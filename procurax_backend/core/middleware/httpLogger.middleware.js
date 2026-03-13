/**
 * HTTP Request Logger Middleware
 * 
 * Logs all incoming HTTP requests with timing and response info.
 */

import logger from "../logging/logger.js";

/**
 * Log incoming requests and their responses
 */
export const httpLogger = (req, res, next) => {
  const start = Date.now();

  // Log request start
  logger.http(`→ ${req.method} ${req.originalUrl}`, {
    requestId: req.id,
    method: req.method,
    url: req.originalUrl,
    ip: req.ip,
    userAgent: req.get("user-agent"),
  });

  // Override res.end to log response
  const originalEnd = res.end;
  res.end = function (chunk, encoding) {
    res.end = originalEnd;
    res.end(chunk, encoding);

    const duration = Date.now() - start;
    const logLevel = res.statusCode >= 400 ? "warn" : "http";

    logger[logLevel](`← ${req.method} ${req.originalUrl} ${res.statusCode} ${duration}ms`, {
      requestId: req.id,
      method: req.method,
      url: req.originalUrl,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      userId: req.userId || null,
    });
  };

  next();
};

export default httpLogger;
