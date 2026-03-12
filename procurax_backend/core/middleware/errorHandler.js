/**
 * Global Error Handler Middleware
 * 
 * Catches all errors thrown in the application and returns
 * a standardized JSON response.
 */

import { AppError } from "../errors/AppError.js";
import logger from "../logging/logger.js";

/**
 * Handle specific error types from external libraries
 */
const handleMongooseValidationError = (err) => {
  const errors = Object.values(err.errors).map((e) => ({
    field: e.path,
    message: e.message,
  }));
  return AppError.validation(errors);
};

const handleMongooseCastError = (err) => {
  return AppError.badRequest(`Invalid ${err.path}: ${err.value}`);
};

const handleMongooseDuplicateKey = (err) => {
  const field = Object.keys(err.keyValue)[0];
  return AppError.conflict(`${field} already exists`);
};

const handleJWTError = () => {
  return AppError.unauthorized("Invalid token. Please log in again.");
};

const handleJWTExpiredError = () => {
  return AppError.unauthorized("Token expired. Please log in again.");
};

/**
 * Development error response - includes stack trace
 */
const sendErrorDev = (err, req, res) => {
  logger.error("Development Error:", {
    error: err.message,
    stack: err.stack,
    requestId: req.id,
    path: req.path,
    method: req.method,
  });

  res.status(err.statusCode).json({
    success: false,
    error: {
      code: err.errorCode,
      message: err.message,
      details: err.details,
      stack: err.stack,
      timestamp: err.timestamp || new Date().toISOString(),
      requestId: req.id,
    },
  });
};

/**
 * Production error response - no sensitive info
 */
const sendErrorProd = (err, req, res) => {
  // Operational, trusted error: send to client
  if (err.isOperational) {
    logger.warn("Operational Error:", {
      code: err.errorCode,
      message: err.message,
      requestId: req.id,
      path: req.path,
    });

    res.status(err.statusCode).json({
      success: false,
      error: {
        code: err.errorCode,
        message: err.message,
        details: err.details,
        timestamp: err.timestamp || new Date().toISOString(),
        requestId: req.id,
      },
    });
  } else {
    // Programming or unknown error: don't leak details
    logger.error("Programming/Unknown Error:", {
      error: err.message,
      stack: err.stack,
      requestId: req.id,
      path: req.path,
    });

    res.status(500).json({
      success: false,
      error: {
        code: "INTERNAL_ERROR",
        message: "Something went wrong. Please try again later.",
        timestamp: new Date().toISOString(),
        requestId: req.id,
      },
    });
  }
};

/**
 * Main error handler middleware
 */
export const errorHandler = (err, req, res, next) => {
  err.statusCode = err.statusCode || 500;
  err.errorCode = err.errorCode || "INTERNAL_ERROR";

  // Handle specific error types
  let error = err;

  if (err.name === "ValidationError") {
    error = handleMongooseValidationError(err);
  }
  if (err.name === "CastError") {
    error = handleMongooseCastError(err);
  }
  if (err.code === 11000) {
    error = handleMongooseDuplicateKey(err);
  }
  if (err.name === "JsonWebTokenError") {
    error = handleJWTError();
  }
  if (err.name === "TokenExpiredError") {
    error = handleJWTExpiredError();
  }

  // Send appropriate response based on environment
  if (process.env.NODE_ENV === "development") {
    sendErrorDev(error, req, res);
  } else {
    sendErrorProd(error, req, res);
  }
};

/**
 * Async handler wrapper to catch async errors
 */
export const asyncHandler = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

/**
 * 404 Not Found handler
 */
export const notFoundHandler = (req, res, next) => {
  next(AppError.notFound(`Route ${req.originalUrl}`));
};

export default errorHandler;
