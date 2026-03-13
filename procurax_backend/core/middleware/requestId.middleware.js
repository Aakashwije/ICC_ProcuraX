/**
 * Request ID Middleware
 * 
 * Assigns a unique correlation ID to each request for tracing.
 */

import { v4 as uuidv4 } from "uuid";

/**
 * Generate and attach request ID to each incoming request
 */
export const requestIdMiddleware = (req, res, next) => {
  // Use existing ID from header or generate new one
  const requestId = req.headers["x-request-id"] || uuidv4();
  
  req.id = requestId;
  res.setHeader("X-Request-Id", requestId);
  
  next();
};

export default requestIdMiddleware;
