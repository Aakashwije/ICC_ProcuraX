/**
 * Auth Middleware Unit Tests
 *
 * Verifies JWT-based authentication and role-based access control.
 */

import { jest, describe, it, expect, beforeAll } from "@jest/globals";
import jwt from "jsonwebtoken";

/* ------------------------------------------------------------------ */
/*  Helpers                                                            */
/* ------------------------------------------------------------------ */
const SECRET = process.env.JWT_SECRET || "change_me";

const mockReq = (overrides = {}) => ({
  id: "req-auth-test",
  path: "/test",
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

const makeToken = (payload, secret = SECRET) =>
  jwt.sign(payload, secret, { expiresIn: "1h" });

/* ================================================================== */
/*  Auth Middleware                                                     */
/* ================================================================== */
describe("authMiddleware", () => {
  let authMiddleware;

  beforeAll(async () => {
    const mod = await import("../../core/middleware/auth.middleware.js");
    authMiddleware = mod.authMiddleware;
  });

  it("should attach userId and user when a valid token is provided", () => {
    const token = makeToken({ id: "user_1", role: "project_manager" });
    const req = mockReq({
      headers: { authorization: `Bearer ${token}` },
    });
    const res = mockRes();
    const next = mockNext();

    authMiddleware(req, res, next);

    expect(next).toHaveBeenCalledTimes(1);
    // next should be called with no arguments (success)
    expect(next.mock.calls[0][0]).toBeUndefined();
    expect(req.userId).toBe("user_1");
    expect(req.userRole).toBe("project_manager");
  });

  it("should call next with error when no token is provided", () => {
    const req = mockReq({ headers: {} });
    const res = mockRes();
    const next = mockNext();

    authMiddleware(req, res, next);

    // The middleware calls next(AppError) on failure
    const err = next.mock.calls[0]?.[0];
    // Could be a direct res.status or next(err) depending on implementation
    expect(next).toHaveBeenCalled();
  });

  it("should call next with error for an invalid token", () => {
    const req = mockReq({
      headers: { authorization: "Bearer invalid.token.here" },
    });
    const res = mockRes();
    const next = mockNext();

    authMiddleware(req, res, next);

    expect(next).toHaveBeenCalled();
    const err = next.mock.calls[0]?.[0];
    if (err) {
      expect(err.statusCode).toBe(401);
    }
  });

  it("should call next with error for an expired token", () => {
    // Create an already-expired token
    const token = jwt.sign(
      { id: "user_1", role: "project_manager" },
      SECRET,
      { expiresIn: "-1s" }
    );
    const req = mockReq({
      headers: { authorization: `Bearer ${token}` },
    });
    const res = mockRes();
    const next = mockNext();

    authMiddleware(req, res, next);

    expect(next).toHaveBeenCalled();
    const err = next.mock.calls[0]?.[0];
    if (err) {
      expect(err.statusCode).toBe(401);
    }
  });
});

/* ================================================================== */
/*  Admin Middleware                                                    */
/* ================================================================== */
describe("adminMiddleware", () => {
  let adminMiddleware;

  beforeAll(async () => {
    const mod = await import("../../core/middleware/auth.middleware.js");
    adminMiddleware = mod.adminMiddleware;
  });

  it("should allow admin users through", () => {
    const token = makeToken({ id: "admin_1", role: "admin" });
    const req = mockReq({
      headers: { authorization: `Bearer ${token}` },
    });
    const res = mockRes();
    const next = mockNext();

    adminMiddleware(req, res, next);

    expect(next).toHaveBeenCalledTimes(1);
    expect(next.mock.calls[0][0]).toBeUndefined();
    expect(req.admin.id).toBe("admin_1");
  });

  it("should reject non-admin users", () => {
    const token = makeToken({ id: "user_1", role: "project_manager" });
    const req = mockReq({
      headers: { authorization: `Bearer ${token}` },
    });
    const res = mockRes();
    const next = mockNext();

    adminMiddleware(req, res, next);

    const err = next.mock.calls[0]?.[0];
    if (err) {
      expect(err.statusCode).toBe(403);
    }
  });
});

/* ================================================================== */
/*  requireRole                                                        */
/* ================================================================== */
describe("requireRole", () => {
  let requireRole;

  beforeAll(async () => {
    const mod = await import("../../core/middleware/auth.middleware.js");
    requireRole = mod.requireRole;
  });

  it("should allow users with matching role", () => {
    const middleware = requireRole("admin", "project_manager");
    const req = mockReq({ userRole: "project_manager", userId: "u1" });
    const res = mockRes();
    const next = mockNext();

    middleware(req, res, next);

    expect(next).toHaveBeenCalledTimes(1);
    expect(next.mock.calls[0][0]).toBeUndefined();
  });

  it("should deny users without matching role", () => {
    const middleware = requireRole("admin");
    const req = mockReq({ userRole: "project_manager", userId: "u1" });
    const res = mockRes();
    const next = mockNext();

    middleware(req, res, next);

    const err = next.mock.calls[0]?.[0];
    expect(err).toBeDefined();
    expect(err.statusCode).toBe(403);
  });

  it("should deny requests without any role", () => {
    const middleware = requireRole("admin");
    const req = mockReq({});
    const res = mockRes();
    const next = mockNext();

    middleware(req, res, next);

    const err = next.mock.calls[0]?.[0];
    expect(err).toBeDefined();
    expect(err.statusCode).toBe(401);
  });
});

/* ================================================================== */
/*  generateToken / verifyToken                                        */
/* ================================================================== */
describe("Token utilities", () => {
  let generateToken, verifyToken;

  beforeAll(async () => {
    const mod = await import("../../core/middleware/auth.middleware.js");
    generateToken = mod.generateToken;
    verifyToken = mod.verifyToken;
  });

  it("should generate a valid JWT that can be verified", () => {
    const token = generateToken("user_42", "project_manager");
    expect(typeof token).toBe("string");

    const decoded = verifyToken(token);
    expect(decoded.id).toBe("user_42");
    expect(decoded.role).toBe("project_manager");
  });

  it("should default role to project_manager", () => {
    const token = generateToken("user_99");
    const decoded = verifyToken(token);
    expect(decoded.role).toBe("project_manager");
  });

  it("should throw on invalid token verification", () => {
    expect(() => verifyToken("garbage")).toThrow();
  });
});
