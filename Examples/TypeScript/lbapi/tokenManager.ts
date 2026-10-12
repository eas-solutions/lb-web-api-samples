import { getConfig, type ConfigOverrides, type LbConfig } from './config.js';
import { ApiError } from './errors.js';
import type { LoginParameter, LoginResponse, UserWeb } from './types.js';

/**
 * Parses the expiration timestamp (in seconds) from a JWT token string.
 */
function parseJwtExp(token: string): number | null {
  try {
    const parts = token.split('.');
    if (parts.length < 2) return null;
    const payloadStr = Buffer.from(parts[1], 'base64url').toString('utf8');
    const payload = JSON.parse(payloadStr) as { exp?: number };
    return typeof payload.exp === 'number' ? payload.exp : null;
  } catch {
    return null;
  }
}

/**
 * Reference TokenManager implementation for the LeegooBuilder Web API.
 *
 * NOTE FOR CONSUMERS:
 * This class is a reference example demonstrating token lifecycle management:
 * - Lazy authentication on first request
 * - Concurrency control: coalescing simultaneous login calls into a single in-flight request
 * - In-memory token caching with proactive refresh when approaching expiration (within 60 seconds)
 * - Cache invalidation on authentication failure
 *
 * Customers and API consumers may implement or adapt this class to match their own
 * application architectures (e.g., distributed cache, Redis, secure credential vaults,
 * or custom identity providers).
 */
export class TokenManager {
  private readonly config: LbConfig;
  private cachedToken: string | null = null;
  private cachedExp: number | null = null;
  private cachedUser: UserWeb | null = null;
  private inFlightLogin: Promise<string> | null = null;

  constructor(config?: ConfigOverrides) {
    this.config = getConfig(config);
  }

  /**
   * Retrieves a valid Bearer access token, acquiring a new one if expired or not yet loaded.
   * Concurrent callers share the same in-flight login request.
   */
  async getToken(): Promise<string> {
    const nowInSeconds = Math.floor(Date.now() / 1000);

    // Return cached token if valid and at least 60 seconds remain before expiration
    if (this.cachedToken && this.cachedExp !== null && this.cachedExp - nowInSeconds > 60) {
      return this.cachedToken;
    }

    // If an authentication request is already in-flight, await and share its result
    if (this.inFlightLogin) {
      return this.inFlightLogin;
    }

    this.inFlightLogin = this.performLogin().finally(() => {
      this.inFlightLogin = null;
    });

    return this.inFlightLogin;
  }

  /**
   * Invalidates the currently cached token so that the next request will acquire a fresh token.
   */
  invalidate(): void {
    this.cachedToken = null;
    this.cachedExp = null;
    this.cachedUser = null;
  }

  /**
   * Returns the cached User information from the last successful login, if available.
   */
  getUser(): UserWeb | null {
    return this.cachedUser;
  }

  /**
   * Explicitly performs login against /api/Authentication/Login and returns the full LoginResponse.
   */
  async login(): Promise<LoginResponse> {
    const url = `${this.config.apiUrl}/Authentication/Login`;
    const payload: LoginParameter = {
      Username: this.config.username,
      UnencryptedPassword: this.config.password,
      Language: this.config.language,
      Culture: this.config.culture,
    };

    let response: Response;
    try {
      response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
        },
        body: JSON.stringify(payload),
      });
    } catch (err) {
      throw new ApiError(
        `Failed to connect to authentication endpoint at ${url}: ${(err as Error).message}`,
        0,
      );
    }

    const data = (await response.json()) as LoginResponse;

    if (!response.ok) {
      const msg = data?.operationResult?.shortMessage ?? `HTTP ${response.status}: ${response.statusText}`;
      throw new ApiError(msg, response.status, data, data?.operationResult);
    }

    if (!data.operationResult?.successful) {
      const msg = data.operationResult?.shortMessage ?? 'Login failed: operationResult reported failure';
      throw new ApiError(msg, response.status, data, data.operationResult);
    }

    if (!data.user?.token) {
      throw new ApiError('Login succeeded but no access token was returned by the server', response.status, data);
    }

    this.cachedToken = data.user.token;
    this.cachedExp = parseJwtExp(this.cachedToken);
    this.cachedUser = data.user;

    return data;
  }

  private async performLogin(): Promise<string> {
    const result = await this.login();
    return result.user!.token!;
  }
}
