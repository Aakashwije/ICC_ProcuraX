/**
 * Unified Authentication Middleware
 * 
 * Single source of truth for all authentication in the application.
 * Supports both user and admin authentication.
 */

import jwt from "jsonwebtoken";
import { secret } from "../../config/jwt.js";
import { AppError } from "../errors/AppError.js";
import logger from "../logging/logger.js";

/**
 * Generate JWT token for a user
 */
export const generateToken = (userId, role = "project_manager", expiresIn = null) => {
  return jwt.sign(
    { id: userId, role },
    secret,
    { expiresIn: expiresIn || process.env.JWT_EXPIRE || "7d" }
  );
};

/**
 * Verify and decode JWT token
 */
export const verifyToken = (token) => {
  return jwt.verify(token, secret);
};

/**
 * Extract token from Authorization header
 */
const extractToken = (req) => {
  const authHeader = req.headers.authorization || "";
  
  if (authHeader.startsWith("Bearer ")) {
    return authHeader.split(" ")[1];
  }
  
  return authHeader || null;
};

/**
 * Main authentication middleware
 * Verifies JWT and attaches user info to request
 */
export const authMiddleware = (req, res, next) => {
  try {
    const token = extractToken(req);

    if (!token) {
      throw AppError.unauthorized("No token provided. Please log in.");
    }

    const decoded = verifyToken(token);
    req.userId = decoded.id;
    req.user = decoded;
    req.userRole = decoded.role;

    logger.debug("User authenticated", {
      userId: decoded.id,
      role: decoded.role,
      requestId: req.id,
    });

    return next();
  } catch (err) {
    if (err.name === "JsonWebTokenError") {
      return next(AppError.unauthorized("Invalid token. Please log in again."));
    }
    if (err.name === "TokenExpiredError") {
      return next(AppError.unauthorized("Token expired. Please log in again."));
    }
    return next(err);
  }
};

/**
 * Admin-only authentication middleware
 * Must be used after authMiddleware
 */
export const adminMiddleware = (req, res, next) => {
  try {
    const token = extractToken(req);

    if (!token) {
      throw AppError.unauthorized("No token provided.");
    }

    const decoded = verifyToken(token);

    if (decoded.role !== "admin") {
      logger.warn("Non-admin access attempt", {
        userId: decoded.id,
        role: decoded.role,
        path: req.path,
        requestId: req.id,
      });
      throw AppError.forbidden("Admin access required.");
    }

    req.userId = decoded.id;
    req.admin = decoded;
    req.userRole = decoded.role;

    return next();
  } catch (err) {
    if (err.name === "JsonWebTokenError") {
      return next(AppError.unauthorized("Invalid token."));
    }
    if (err.name === "TokenExpiredError") {
      return next(AppError.unauthorized("Token expired."));
    }
    return next(err);
  }
};

/**
 * Optional authentication middleware
 * Doesn't fail if no token, but attaches user if present
 */
export const optionalAuth = (req, res, next) => {
  try {
    const token = extractToken(req);

    if (token) {
      const decoded = verifyToken(token);
      req.userId = decoded.id;
      req.user = decoded;
      req.userRole = decoded.role;
    }

    return next();
  } catch (err) {
    // Token invalid but optional, continue without user
    logger.debug("Optional auth failed, continuing as guest", {
      requestId: req.id,
    });
    return next();
  }
};

/**
 * Role-based access control middleware factory
 * Usage: requireRole("admin", "project_manager")
 */
export const requireRole = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.userRole) {
      return next(AppError.unauthorized("Authentication required."));
    }

    if (!allowedRoles.includes(req.userRole)) {
      logger.warn("Role access denied", {
        userId: req.userId,
        userRole: req.userRole,
        requiredRoles: allowedRoles,
        path: req.path,
        requestId: req.id,
      });
      return next(
        AppError.forbidden(
          `Access denied. Required role: ${allowedRoles.join(" or ")}`
        )
      );
    }

    return next();
  };
};

// Default export for backward compatibility
export default authMiddleware;
