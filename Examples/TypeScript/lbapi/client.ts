import { getConfig, type ConfigOverrides, type LbConfig } from './config.js';
import { ApiError } from './errors.js';
import { TokenManager } from './tokenManager.js';
import { OperationFailType, type OperationResult } from './types.js';

export interface RequestOptions {
  /** If true, no Bearer token is attached to the request */
  anonymous?: boolean;
}

/**
 * HTTP client for communicating with the LeegooBuilder Web API.
 * Uses native fetch and exchanges only JSON data.
 */
export class LbClient {
  readonly config: LbConfig;
  readonly tokenManager: TokenManager;

  constructor(config?: ConfigOverrides, tokenManager?: TokenManager) {
    this.config = getConfig(config);
    this.tokenManager = tokenManager ?? new TokenManager(this.config);
  }

  /**
   * Sends a POST request with a JSON payload to the specified relative API path.
   *
   * Automatically adds Authorization Bearer token obtained from TokenManager.
   * If an HTTP 401 or an OperationResult indicating NotLoggedIn (10) or TokenInvalid (20)
   * is received, the cached token is invalidated and the request is retried once.
   */
  async postJson<TReq, TRes>(path: string, body: TReq, options?: RequestOptions): Promise<TRes> {
    const url = `${this.config.apiUrl}/${path.replace(/^\//, '')}`;

    const execute = async (isRetry: boolean): Promise<TRes> => {
      const headers: Record<string, string> = {
        'Content-Type': 'application/json',
        Accept: 'application/json',
      };

      if (!options?.anonymous) {
        const token = await this.tokenManager.getToken();
        headers['Authorization'] = `Bearer ${token}`;
      }

      let response: Response;
      try {
        response = await fetch(url, {
          method: 'POST',
          headers,
          body: JSON.stringify(body),
        });
      } catch (err) {
        throw new ApiError(
          `Request to ${url} failed to connect: ${(err as Error).message}`,
          0,
        );
      }

      // Check for HTTP 401 Unauthorized
      if (!options?.anonymous && !isRetry && response.status === 401) {
        this.tokenManager.invalidate();
        return execute(true);
      }

      let data: unknown;
      try {
        data = await response.json();
      } catch {
        // If the body is not valid JSON
        if (!response.ok) {
          throw new ApiError(`HTTP ${response.status}: ${response.statusText}`, response.status);
        }
        throw new ApiError('Failed to parse response body as JSON', response.status);
      }

      const resultWithOp = data as { operationResult?: OperationResult } | undefined;
      const opResult = resultWithOp?.operationResult;

      // Check for auth-related operation failures (NotLoggedIn = 10, TokenInvalid = 20, TokenExpired = 80)
      if (!options?.anonymous && !isRetry && opResult) {
        const failType = opResult.operationFailType;
        if (
          failType === OperationFailType.NotLoggedIn ||
          failType === OperationFailType.TokenInvalid ||
          failType === OperationFailType.TokenExpired
        ) {
          this.tokenManager.invalidate();
          return execute(true);
        }
      }

      // If operationResult indicates failure
      if (opResult && opResult.successful === false) {
        const message = opResult.shortMessage || 'Operation reported failure';
        throw new ApiError(message, response.status, data, opResult);
      }

      // If HTTP status is not 2xx
      if (!response.ok) {
        const message = opResult?.shortMessage ?? `HTTP ${response.status}: ${response.statusText}`;
        throw new ApiError(message, response.status, data, opResult);
      }

      return data as TRes;
    };

    return execute(false);
  }
}

/**
 * Creates a new LbClient instance with optional configuration overrides.
 */
export function createClient(config?: ConfigOverrides, tokenManager?: TokenManager): LbClient {
  return new LbClient(config, tokenManager);
}
