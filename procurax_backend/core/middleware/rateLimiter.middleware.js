/**
 * Rate Limiting Middleware
 * 
 * Configurable rate limiters for different endpoints.
 */

import rateLimit from "express-rate-limit";
import { AppError } from "../errors/AppError.js";
import logger from "../logging/logger.js";

/**
 * Default rate limit handler
 */
const rateLimitHandler = (req, res, next, options) => {
  logger.warn("Rate limit exceeded", {
    ip: req.ip,
    path: req.path,
    requestId: req.id,
  });
  
  next(AppError.tooManyRequests(options.message));
};

/**
 * Standard API rate limiter
 * 100 requests per 15 minutes
 */
export const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  message: "Too many requests, please try again later",
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler,
  skip: (req) => {
    // Skip rate limiting in development
    return process.env.NODE_ENV === "development";
  },
});

/**
 * Strict rate limiter for authentication endpoints
 * 5 requests per 15 minutes
 */
export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5,
  message: "Too many authentication attempts, please try again after 15 minutes",
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler,
  skipFailedRequests: false,
});

/**
 * Password reset rate limiter
 * 3 requests per 15 minutes
 */
export const passwordResetLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 3,
  message: "Too many password reset attempts, please try again after 15 minutes",
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler,
});

/**
 * Account creation rate limiter
 * 5 accounts per hour per IP
 */
export const registrationLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 5,
  message: "Too many accounts created, please try again after an hour",
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler,
});

/**
 * File upload rate limiter
 * 20 uploads per 15 minutes
 */
export const uploadLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20,
  message: "Too many file uploads, please try again later",
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler,
});

/**
 * Custom rate limiter factory
 */
export const createRateLimiter = (options) => {
  return rateLimit({
    windowMs: options.windowMs || 15 * 60 * 1000,
    max: options.max || 100,
    message: options.message || "Too many requests, please try again later",
    standardHeaders: true,
    legacyHeaders: false,
    handler: rateLimitHandler,
    skip: options.skip,
    keyGenerator: options.keyGenerator,
  });
};

export default {
  apiLimiter,
  authLimiter,
  passwordResetLimiter,
  registrationLimiter,
  uploadLimiter,
  createRateLimiter,
};
