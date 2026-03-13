/**
 * Validation Middleware Unit Tests
 *
 * Tests Joi-based request validation middleware.
 */

import { jest, describe, it, expect } from "@jest/globals";
import Joi from "joi";
import {
  validateBody,
  validateQuery,
  validateObjectId,
} from "../../core/validation/validate.middleware.js";
import { AppError } from "../../core/errors/AppError.js";

/* ------------------------------------------------------------------ */
/*  Helpers                                                            */
/* ------------------------------------------------------------------ */
const mockReq = (overrides = {}) => ({
  body: {},
  query: {},
  params: {},
  ...overrides,
});

const mockRes = () => ({
  status: jest.fn().mockReturnThis(),
  json: jest.fn().mockReturnThis(),
});

const mockNext = () => jest.fn();

/* ------------------------------------------------------------------ */
/*  Schemas for testing                                                */
/* ------------------------------------------------------------------ */
const taskSchema = Joi.object({
  title: Joi.string().min(1).max(200).required(),
  priority: Joi.string().valid("low", "medium", "high").default("medium"),
});

const querySchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
});

/* ================================================================== */
/*  validateBody                                                       */
/* ================================================================== */
describe("validateBody", () => {
  const middleware = validateBody(taskSchema);

  it("should pass valid data and attach validatedBody", () => {
    const req = mockReq({ body: { title: "My Task", priority: "high" } });
    const res = mockRes();
    const next = mockNext();

    middleware(req, res, next);

    expect(next).toHaveBeenCalledTimes(1);
    expect(next.mock.calls[0][0]).toBeUndefined();
    expect(req.validatedBody.title).toBe("My Task");
    expect(req.validatedBody.priority).toBe("high");
  });

  it("should apply defaults from schema", () => {
    const req = mockReq({ body: { title: "Task" } });
    const res = mockRes();
    const next = mockNext();

    middleware(req, res, next);

    expect(req.validatedBody.priority).toBe("medium");
  });

  it("should strip unknown fields", () => {
    const req = mockReq({
      body: { title: "Task", unknownField: "hacker" },
    });
    const res = mockRes();
    const next = mockNext();

    middleware(req, res, next);

    expect(req.validatedBody.unknownField).toBeUndefined();
  });

  it("should return validation error when title is missing", () => {
    const req = mockReq({ body: {} });
    const res = mockRes();
    const next = mockNext();

    middleware(req, res, next);

    const err = next.mock.calls[0][0];
    expect(err).toBeInstanceOf(AppError);
    expect(err.statusCode).toBe(422);
    expect(err.details).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ field: "title" }),
      ])
    );
  });

  it("should return validation error for invalid priority", () => {
    const req = mockReq({ body: { title: "OK", priority: "urgent" } });
    const res = mockRes();
    const next = mockNext();

    middleware(req, res, next);

    const err = next.mock.calls[0][0];
    expect(err).toBeInstanceOf(AppError);
    expect(err.statusCode).toBe(422);
  });
});

/* ================================================================== */
/*  validateQuery                                                      */
/* ================================================================== */
describe("validateQuery", () => {
  const middleware = validateQuery(querySchema);

  it("should pass valid query params", () => {
    const req = mockReq({ query: { page: "2", limit: "10" } });
    const res = mockRes();
    const next = mockNext();

    middleware(req, res, next);

    expect(next).toHaveBeenCalledTimes(1);
    expect(req.validatedQuery.page).toBe(2);
    expect(req.validatedQuery.limit).toBe(10);
  });

  it("should apply defaults for missing params", () => {
    const req = mockReq({ query: {} });
    const res = mockRes();
    const next = mockNext();

    middleware(req, res, next);

    expect(req.validatedQuery.page).toBe(1);
    expect(req.validatedQuery.limit).toBe(20);
  });

  it("should reject invalid query values", () => {
    const req = mockReq({ query: { page: "-1" } });
    const res = mockRes();
    const next = mockNext();

    middleware(req, res, next);

    const err = next.mock.calls[0][0];
    expect(err).toBeInstanceOf(AppError);
  });
});

/* ================================================================== */
/*  validateObjectId                                                   */
/* ================================================================== */
describe("validateObjectId", () => {
  const middleware = validateObjectId("id");

  it("should accept a valid 24-char hex string", () => {
    const req = mockReq({ params: { id: "507f1f77bcf86cd799439011" } });
    const res = mockRes();
    const next = mockNext();

    middleware(req, res, next);

    expect(next).toHaveBeenCalledTimes(1);
    expect(next.mock.calls[0][0]).toBeUndefined();
  });

  it("should reject a short string", () => {
    const req = mockReq({ params: { id: "abc123" } });
    const res = mockRes();
    const next = mockNext();

    middleware(req, res, next);

    const err = next.mock.calls[0][0];
    expect(err).toBeInstanceOf(AppError);
    expect(err.statusCode).toBe(400);
  });

  it("should reject a missing id", () => {
    const req = mockReq({ params: {} });
    const res = mockRes();
    const next = mockNext();

    middleware(req, res, next);

    const err = next.mock.calls[0][0];
    expect(err).toBeInstanceOf(AppError);
    expect(err.statusCode).toBe(400);
  });

  it("should reject non-hex characters", () => {
    const req = mockReq({ params: { id: "zzzzzzzzzzzzzzzzzzzzzzzz" } });
    const res = mockRes();
    const next = mockNext();

    middleware(req, res, next);

    const err = next.mock.calls[0][0];
    expect(err).toBeInstanceOf(AppError);
  });
});
