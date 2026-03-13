/**
 * Validation Middleware Factory
 * 
 * Creates middleware that validates request data against Joi schemas.
 */

import { AppError } from "../errors/AppError.js";

/**
 * Validate request body against schema
 */
export const validateBody = (schema) => {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      const errors = error.details.map((detail) => ({
        field: detail.path.join("."),
        message: detail.message,
      }));
      return next(AppError.validation(errors));
    }

    req.validatedBody = value;
    next();
  };
};

/**
 * Validate request query parameters against schema
 */
export const validateQuery = (schema) => {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.query, {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      const errors = error.details.map((detail) => ({
        field: detail.path.join("."),
        message: detail.message,
      }));
      return next(AppError.validation(errors));
    }

    req.validatedQuery = value;
    next();
  };
};

/**
 * Validate request params against schema
 */
export const validateParams = (schema) => {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.params, {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      const errors = error.details.map((detail) => ({
        field: detail.path.join("."),
        message: detail.message,
      }));
      return next(AppError.validation(errors));
    }

    req.validatedParams = value;
    next();
  };
};

/**
 * Validate ObjectId parameter
 */
export const validateObjectId = (paramName = "id") => {
  return (req, res, next) => {
    const id = req.params[paramName];
    const objectIdRegex = /^[0-9a-fA-F]{24}$/;

    if (!id || !objectIdRegex.test(id)) {
      return next(AppError.badRequest(`Invalid ${paramName} format`));
    }

    next();
  };
};

export default {
  validateBody,
  validateQuery,
  validateParams,
  validateObjectId,
};
