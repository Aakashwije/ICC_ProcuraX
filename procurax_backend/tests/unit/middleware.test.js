/**
 * ============================================================================
 * Express Middleware Suite — Comprehensive Unit Tests
 * ============================================================================
 *
 * @file tests/unit/middleware.test.js
 * @description
 *   Tests the core Express middleware stack components:
 *   - errorHandler: Centralized error response formatting (AppError, Mongoose validation)
 *   - asyncHandler: Wrapper for async route handlers (prevents unhandled rejections)
 *   - notFoundHandler: 404 response for undefined routes
 *   - Error type detection: CastError, ValidationError, DuplicateKey handling
 *   - AppError custom error class (400, 401, 403, 404, 422, 500 status codes)
 *
 * @coverage
 *   - Error handler: 6 tests (AppError, ValidationError, CastError, generic)
 *   - Async handler: 2 tests (success, rejection propagation)
 *   - NotFound handler: 1 test (404 response)
 *   - Total: 9 middleware test cases
 *
 * @dependencies
 *   - AppError (custom error class)
 *   - Express req/res/next (mocked)
 *   - Mongoose validation errors
 *   - Jest spies for error handling verification
 *
 * @error_handling_strategy
 *   - Detects error.name to classify: ValidationError, CastError, etc.
 *   - Wraps errors in AppError for consistent response format
 *   - Logs original errors before responding
 *   - Distinguishes development vs production responses
 *
 * @response_format
 *   {
 *     "success": false,
 *     "error": {
 *       "code": "ERROR_CODE",
 *       "message": "User-friendly message",
 *       "details": {...} // dev only
 *     }
 *   }
 */

import { jest, describe, it, expect, beforeAll, beforeEach } from "@jest/globals";
import { AppError } from "../../core/errors/AppError.js";

/* ────────────────────────────────────────────────────────────────────
   HELPER FUNCTIONS: Express req/res/next Mocks
   ────────────────────────────────────────────────────────────────────
   @param {Object} overrides - Partial req overrides
   @returns {Object} Mock Express request object
*/
const mockReq = (overrides = {}) => ({
  id: "req-123",
  path: "/test",
  method: "GET",
  originalUrl: "/api/v1/test",
  headers: {},
  ...overrides,
});

const mockRes = () => {
  const res = {
    statusCode: 200,
    _body: null,
    status: jest.fn(function (code) {
      this.statusCode = code;
      return this;
    }),
    json: jest.fn(function (body) {
      this._body = body;
      return this;
    }),
  };
  return res;
};

const mockNext = () => jest.fn();

/* ================================================================== */
/*  Error Handler                                                      */
/* ================================================================== */
describe("errorHandler middleware", () => {
  let errorHandler, asyncHandler, notFoundHandler;

  beforeAll(async () => {
    // Dynamic import to avoid hoisting issues
    const mod = await import("../../core/middleware/errorHandler.js");
    errorHandler = mod.errorHandler;
    asyncHandler = mod.asyncHandler;
    notFoundHandler = mod.notFoundHandler;
  });

  it("should return JSON with status code from AppError", () => {
    const err = AppError.badRequest("Bad input");
    const req = mockReq();
    const res = mockRes();
    const next = mockNext();

    // Force test env so we hit sendErrorDev branch
    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = "development";

    errorHandler(err, req, res, next);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res._body.success).toBe(false);
    expect(res._body.error.code).toBe("BAD_REQUEST");

    process.env.NODE_ENV = originalEnv;
  });

  it("should handle Mongoose ValidationError", () => {
    const err = new Error("Validation failed");
    err.name = "ValidationError";
    err.errors = {
      title: { path: "title", message: "Title is required" },
    };
    const req = mockReq();
    const res = mockRes();

    process.env.NODE_ENV = "development";
    errorHandler(err, req, res, mockNext());

    expect(res.status).toHaveBeenCalledWith(422);
    process.env.NODE_ENV = "test";
  });

  it("should handle Mongoose CastError", () => {
    const err = new Error("Cast failed");
    err.name = "CastError";
    err.path = "_id";
    err.value = "not-an-id";
    const req = mockReq();
    const res = mockRes();

    process.env.NODE_ENV = "development";
    errorHandler(err, req, res, mockNext());

    expect(res.status).toHaveBeenCalledWith(400);
    process.env.NODE_ENV = "test";
  });

  it("should handle MongoDB duplicate key error (code 11000)", () => {
    const err = new Error("Duplicate");
    err.code = 11000;
    err.keyValue = { email: "test@example.com" };
    const req = mockReq();
    const res = mockRes();

    process.env.NODE_ENV = "development";
    errorHandler(err, req, res, mockNext());

    expect(res.status).toHaveBeenCalledWith(409);
    process.env.NODE_ENV = "test";
  });

  it("should handle JWT errors", () => {
    const err = new Error("jwt malformed");
    err.name = "JsonWebTokenError";
    const req = mockReq();
    const res = mockRes();

    process.env.NODE_ENV = "development";
    errorHandler(err, req, res, mockNext());

    expect(res.status).toHaveBeenCalledWith(401);
    process.env.NODE_ENV = "test";
  });

  it("should handle expired JWT", () => {
    const err = new Error("jwt expired");
    err.name = "TokenExpiredError";
    const req = mockReq();
    const res = mockRes();

    process.env.NODE_ENV = "development";
    errorHandler(err, req, res, mockNext());

    expect(res.status).toHaveBeenCalledWith(401);
    process.env.NODE_ENV = "test";
  });

  it("should default to 500 for unknown errors in production", () => {
    const err = new Error("Something broke");
    const req = mockReq();
    const res = mockRes();

    process.env.NODE_ENV = "production";
    errorHandler(err, req, res, mockNext());

    expect(res.status).toHaveBeenCalledWith(500);
    expect(res._body.error.code).toBe("INTERNAL_ERROR");
    // Should NOT leak stack trace
    expect(res._body.error.stack).toBeUndefined();
    process.env.NODE_ENV = "test";
  });
});

/* ================================================================== */
/*  Async Handler                                                      */
/* ================================================================== */
describe("asyncHandler", () => {
  let asyncHandler;

  beforeAll(async () => {
    const mod = await import("../../core/middleware/errorHandler.js");
    asyncHandler = mod.asyncHandler;
  });

  it("should call the wrapped function normally", async () => {
    const handler = jest.fn((req, res) => res.json({ ok: true }));
    const wrapped = asyncHandler(handler);
    const req = mockReq();
    const res = mockRes();
    const next = mockNext();

    await wrapped(req, res, next);

    expect(handler).toHaveBeenCalledWith(req, res, next);
    expect(next).not.toHaveBeenCalled();
  });

  it("should forward async errors to next()", async () => {
    const error = new Error("Async failure");
    const handler = jest.fn().mockRejectedValue(error);
    const wrapped = asyncHandler(handler);
    const req = mockReq();
    const res = mockRes();
    const next = mockNext();

    await wrapped(req, res, next);

    expect(next).toHaveBeenCalledWith(error);
  });
});

/* ================================================================== */
/*  Not-Found Handler                                                  */
/* ================================================================== */
describe("notFoundHandler", () => {
  let notFoundHandler;

  beforeAll(async () => {
    const mod = await import("../../core/middleware/errorHandler.js");
    notFoundHandler = mod.notFoundHandler;
  });

  it("should call next() with a 404 AppError", () => {
    const req = mockReq({ originalUrl: "/api/v1/missing" });
    const res = mockRes();
    const next = mockNext();

    notFoundHandler(req, res, next);

    expect(next).toHaveBeenCalledTimes(1);
    const err = next.mock.calls[0][0];
    expect(err).toBeInstanceOf(AppError);
    expect(err.statusCode).toBe(404);
  });
});

/* ================================================================== */
/*  AppError Factory Methods                                           */
/* ================================================================== */
describe("AppError", () => {
  it("should create a forbidden error (403)", () => {
    const err = AppError.forbidden("Access denied");
    expect(err).toBeInstanceOf(AppError);
    expect(err.statusCode).toBe(403);
    expect(err.errorCode).toBe("FORBIDDEN");
    expect(err.message).toBe("Access denied");
  });

  it("should create a notFound error (404)", () => {
    const err = AppError.notFound("User");
    expect(err.statusCode).toBe(404);
    expect(err.errorCode).toBe("NOT_FOUND");
    expect(err.message).toBe("User not found");
  });

  it("should create a tooManyRequests error (429)", () => {
    const err = AppError.tooManyRequests();
    expect(err.statusCode).toBe(429);
    expect(err.errorCode).toBe("RATE_LIMIT_EXCEEDED");
    expect(err.isOperational).toBe(true);
  });

  it("should create an internal error (500)", () => {
    const err = AppError.internal("DB crashed");
    expect(err.statusCode).toBe(500);
    expect(err.errorCode).toBe("INTERNAL_ERROR");
    expect(err.message).toBe("DB crashed");
  });

  it("should create a serviceUnavailable error (503)", () => {
    const err = AppError.serviceUnavailable();
    expect(err.statusCode).toBe(503);
    expect(err.errorCode).toBe("SERVICE_UNAVAILABLE");
  });

  it("should serialise to JSON via toJSON()", () => {
    const err = AppError.badRequest("Missing field", { field: "email" });
    const json = err.toJSON();
    expect(json.success).toBe(false);
    expect(json.error.code).toBe("BAD_REQUEST");
    expect(json.error.message).toBe("Missing field");
    expect(json.error.details).toEqual({ field: "email" });
    expect(json.error.timestamp).toBeDefined();
  });

  it("should include stack trace in toJSON() in development mode", () => {
    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = "development";
    const err = AppError.internal();
    const json = err.toJSON();
    expect(json.error.stack).toBeDefined();
    process.env.NODE_ENV = originalEnv;
  });
});

/* ================================================================== */
/*  Cache Service                                                      */
/* ================================================================== */
describe("CacheService", () => {
  let CacheService;

  beforeAll(async () => {
    // Redis must be initialised before CacheService tries to use the client.
    // Without REDIS_URL this gives us the in-memory fallback.
    const redisMod = await import("../../core/services/redis.service.js");
    await redisMod.default.connect();

    const mod = await import("../../core/services/cache.service.js");
    CacheService = mod.default;
  });

  beforeEach(async () => {
    await CacheService.clear();
    // Reset stats between tests
    CacheService._stats = { hits: 0, misses: 0, sets: 0, evictions: 0 };
  });

  it("should set and get a value", async () => {
    await CacheService.set("key1", { data: "hello" });
    expect(await CacheService.get("key1")).toEqual({ data: "hello" });
  });

  it("should return null for missing keys", async () => {
    expect(await CacheService.get("nonexistent")).toBeNull();
  });

  it("should delete a key", async () => {
    await CacheService.set("key2", "value");
    await CacheService.delete("key2");
    expect(await CacheService.get("key2")).toBeNull();
  });

  it("should invalidate keys by prefix", async () => {
    await CacheService.set("user:1:profile", "data1");
    await CacheService.set("user:1:tasks", "data2");
    await CacheService.set("user:2:profile", "data3");

    await CacheService.invalidatePrefix("user:1");

    expect(await CacheService.get("user:1:profile")).toBeNull();
    expect(await CacheService.get("user:1:tasks")).toBeNull();
    expect(await CacheService.get("user:2:profile")).toEqual("data3");
  });

  it("should expire entries after TTL", async () => {
    // set() takes TTL in seconds — use a fractional second for test speed
    await CacheService.set("short", "value", 0.1); // 0.1 second TTL
    expect(await CacheService.get("short")).toBe("value");

    await new Promise((r) => setTimeout(r, 200));
    expect(await CacheService.get("short")).toBeNull();
  });

  it("should return cache stats", async () => {
    await CacheService.set("a", 1);
    await CacheService.get("a"); // hit
    await CacheService.get("b"); // miss

    const stats = CacheService.getStats();
    expect(stats.hits).toBeGreaterThanOrEqual(1);
    expect(stats.misses).toBeGreaterThanOrEqual(1);
    expect(stats.size).toBeGreaterThanOrEqual(1);
  });
});

/* ================================================================== */
/*  Job Queue                                                          */
/* ================================================================== */
describe("JobQueue", () => {
  let jobQueue;

  beforeAll(async () => {
    // Ensure Redis fallback is ready (may already be connected from CacheService tests)
    const redisMod = await import("../../core/services/redis.service.js");
    if (!redisMod.default._client) {
      await redisMod.default.connect();
    }

    const mod = await import("../../core/services/jobQueue.js");
    jobQueue = mod.default;

    // Initialise the queue — selects Bull or in-process backend
    await jobQueue.init();
  });

  it("should register a handler and process a job", async () => {
    const handler = jest.fn().mockResolvedValue("done");
    jobQueue.registerHandler("test_job", handler);

    await jobQueue.enqueue("test_job", { key: "value" });

    // Give queue time to process - in-process queue should process immediately
    await new Promise((r) => setTimeout(r, 500));

    expect(handler).toHaveBeenCalledWith(
      expect.objectContaining({ key: "value" })
    );
  });

  it("should return queue stats", async () => {
    const stats = await jobQueue.getStats();
    expect(stats).toHaveProperty("processed");
    expect(stats).toHaveProperty("failed");  
    expect(stats).toHaveProperty("enqueued");
  });
});
