/**
 * AppError - Centralized application error class
 * 
 * This class provides a standardized way to create and handle errors
 * throughout the application. All business logic errors should use this class.
 */

export class AppError extends Error {
  constructor(message, statusCode = 500, errorCode = null, details = null) {
    super(message);
    
    this.statusCode = statusCode;
    this.errorCode = errorCode || `ERR_${statusCode}`;
    this.details = details;
    this.isOperational = true; // Distinguishes from programming errors
    this.timestamp = new Date().toISOString();
    
    Error.captureStackTrace(this, this.constructor);
  }

  /**
   * Factory methods for common error types
   */
  
  static badRequest(message = "Bad request", details = null) {
    return new AppError(message, 400, "BAD_REQUEST", details);
  }

  static unauthorized(message = "Unauthorized access") {
    return new AppError(message, 401, "UNAUTHORIZED");
  }

  static forbidden(message = "Access forbidden") {
    return new AppError(message, 403, "FORBIDDEN");
  }

  static notFound(resource = "Resource") {
    return new AppError(`${resource} not found`, 404, "NOT_FOUND");
  }

  static conflict(message = "Resource conflict") {
    return new AppError(message, 409, "CONFLICT");
  }

  static validation(errors) {
    return new AppError("Validation failed", 422, "VALIDATION_ERROR", errors);
  }

  static tooManyRequests(message = "Too many requests, please try again later") {
    return new AppError(message, 429, "RATE_LIMIT_EXCEEDED");
  }

  static internal(message = "Internal server error") {
    return new AppError(message, 500, "INTERNAL_ERROR");
  }

  static serviceUnavailable(message = "Service temporarily unavailable") {
    return new AppError(message, 503, "SERVICE_UNAVAILABLE");
  }

  /**
   * Convert error to JSON response format
   */
  toJSON() {
    return {
      success: false,
      error: {
        code: this.errorCode,
        message: this.message,
        details: this.details,
        timestamp: this.timestamp,
        ...(process.env.NODE_ENV === "development" && { stack: this.stack })
      }
    };
  }
}

export default AppError;
