/**
 * Core Module Index
 * 
 * Central export for all core infrastructure components.
 */

// Errors
export { AppError } from "./errors/AppError.js";

// Middleware
export {
  errorHandler,
  asyncHandler,
  notFoundHandler,
} from "./middleware/errorHandler.js";

export {
  authMiddleware,
  adminMiddleware,
  optionalAuth,
  requireRole,
  generateToken,
  verifyToken,
} from "./middleware/auth.middleware.js";

export { requestIdMiddleware } from "./middleware/requestId.middleware.js";
export { httpLogger } from "./middleware/httpLogger.middleware.js";

export {
  apiLimiter,
  authLimiter,
  passwordResetLimiter,
  registrationLimiter,
  uploadLimiter,
  createRateLimiter,
} from "./middleware/rateLimiter.middleware.js";

// Validation
export {
  validateBody,
  validateQuery,
  validateParams,
  validateObjectId,
} from "./validation/validate.middleware.js";

export {
  authSchemas,
  taskSchemas,
  noteSchemas,
  meetingSchemas,
  projectSchemas,
  userSchemas,
  notificationSchemas,
} from "./validation/schemas.js";

// Services
export { default as TaskService } from "./services/task.service.js";
export { default as NoteService } from "./services/note.service.js";
export { default as MeetingService } from "./services/meeting.service.js";

// Logging
export { default as logger } from "./logging/logger.js";

// Configuration
export { validateEnvironment, getConfig } from "./config/envValidator.js";
