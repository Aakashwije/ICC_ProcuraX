/**
 * Distributed Tracing Middleware
 *
 * Implements W3C Trace Context-compatible distributed tracing.
 * Each request gets a trace ID and span ID propagated via headers,
 * enabling end-to-end request tracking across microservices.
 *
 * Headers:
 *   - X-Trace-Id       — unique trace identifier (propagated from client or generated)
 *   - X-Span-Id        — unique span identifier for this service hop
 *   - X-Parent-Span-Id — span ID of the calling service (if present)
 *   - X-Request-Id     — existing correlation ID (kept for backward compat)
 *
 * All IDs are attached to `req.tracing` and injected into Winston logs
 * via the httpLogger middleware, enabling log correlation in Grafana/ELK.
 */

import { v4 as uuidv4 } from "uuid";
import logger from "../logging/logger.js";

/**
 * Generate a short hex span ID (16 chars).
 */
const generateSpanId = () => {
  return uuidv4().replace(/-/g, "").substring(0, 16);
};

/**
 * Distributed tracing middleware.
 */
export const tracingMiddleware = (req, res, next) => {
  // Extract or generate trace ID
  const traceId = req.headers["x-trace-id"] || req.headers["traceparent"]?.split("-")[1] || uuidv4();
  const parentSpanId = req.headers["x-span-id"] || req.headers["x-parent-span-id"] || null;
  const spanId = generateSpanId();

  // Attach tracing context to request
  req.tracing = {
    traceId,
    spanId,
    parentSpanId,
    startTime: process.hrtime.bigint(),
    serviceName: "procurax-backend",
  };

  // Also keep backward-compat request ID
  if (!req.id) {
    req.id = traceId;
  }

  // Set response headers for downstream propagation
  res.setHeader("X-Trace-Id", traceId);
  res.setHeader("X-Span-Id", spanId);
  if (parentSpanId) {
    res.setHeader("X-Parent-Span-Id", parentSpanId);
  }

  // W3C traceparent header: version-traceId-spanId-flags
  res.setHeader(
    "traceparent",
    `00-${traceId.replace(/-/g, "").padEnd(32, "0").substring(0, 32)}-${spanId}-01`
  );

  // Log span start at debug level
  logger.debug("Span started", {
    traceId,
    spanId,
    parentSpanId,
    method: req.method,
    path: req.path,
  });

  // On response finish, log the span completion with duration
  const onFinish = () => {
    const durationNs = Number(process.hrtime.bigint() - req.tracing.startTime);
    const durationMs = durationNs / 1_000_000;

    logger.debug("Span completed", {
      traceId,
      spanId,
      parentSpanId,
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      durationMs: Math.round(durationMs * 100) / 100,
    });

    res.removeListener("finish", onFinish);
  };

  res.on("finish", onFinish);
  next();
};

export default tracingMiddleware;
