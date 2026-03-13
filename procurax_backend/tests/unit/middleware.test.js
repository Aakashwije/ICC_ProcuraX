/**
 * Middleware Unit Tests
 *
 * Tests the core middleware stack: error handler, async handler,
 * auth middleware, and request-ID middleware.
 */

import { jest, describe, it, expect, beforeAll, beforeEach } from "@jest/globals";
import { AppError } from "../../core/errors/AppError.js";

/* ------------------------------------------------------------------ */
/*  Helpers: mock Express req / res / next                             */
/* ------------------------------------------------------------------ */
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
/*  Cache Service                                                      */
/* ================================================================== */
describe("CacheService", () => {
  let CacheService;

  beforeAll(async () => {
    const mod = await import("../../core/services/cache.service.js");
    CacheService = mod.default;
  });

  beforeEach(() => {
    CacheService.clear();
  });

  it("should set and get a value", () => {
    CacheService.set("key1", { data: "hello" });
    expect(CacheService.get("key1")).toEqual({ data: "hello" });
  });

  it("should return null for missing keys", () => {
    expect(CacheService.get("nonexistent")).toBeNull();
  });

  it("should delete a key", () => {
    CacheService.set("key2", "value");
    CacheService.delete("key2");
    expect(CacheService.get("key2")).toBeNull();
  });

  it("should invalidate keys by prefix", () => {
    CacheService.set("user:1:profile", "data1");
    CacheService.set("user:1:tasks", "data2");
    CacheService.set("user:2:profile", "data3");

    CacheService.invalidatePrefix("user:1");

    expect(CacheService.get("user:1:profile")).toBeNull();
    expect(CacheService.get("user:1:tasks")).toBeNull();
    expect(CacheService.get("user:2:profile")).toEqual("data3");
  });

  it("should expire entries after TTL", async () => {
    // set() takes TTL in seconds — use a fractional second for test speed
    CacheService.set("short", "value", 0.1); // 0.1 second TTL
    expect(CacheService.get("short")).toBe("value");

    await new Promise((r) => setTimeout(r, 200));
    expect(CacheService.get("short")).toBeNull();
  });

  it("should return cache stats", () => {
    CacheService.set("a", 1);
    CacheService.get("a"); // hit
    CacheService.get("b"); // miss

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
    const mod = await import("../../core/services/jobQueue.js");
    jobQueue = mod.default;
  });

  it("should register a handler and process a job", async () => {
    const handler = jest.fn().mockResolvedValue("done");
    jobQueue.registerHandler("test_job", handler);

    await jobQueue.enqueue("test_job", { key: "value" });

    // Give queue time to process
    await new Promise((r) => setTimeout(r, 200));

    expect(handler).toHaveBeenCalledWith(
      expect.objectContaining({ key: "value" })
    );
  });

  it("should return queue stats", () => {
    const stats = jobQueue.getStats();
    expect(stats).toHaveProperty("processed");
    expect(stats).toHaveProperty("failed");
    expect(stats).toHaveProperty("enqueued");
  });
});
