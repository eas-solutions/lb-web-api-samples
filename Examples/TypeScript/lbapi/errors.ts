import type { OperationResult } from './types.js';

/**
 * Error thrown when an API request fails either at the HTTP transport level
 * or when the returned OperationResult indicates a failure (successful === false).
 */
export class ApiError extends Error {
  readonly status: number;
  readonly responseBody?: unknown;
  readonly operationResult?: OperationResult;

  constructor(message: string, status: number, responseBody?: unknown, operationResult?: OperationResult) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.responseBody = responseBody;
    this.operationResult = operationResult;
  }
}
