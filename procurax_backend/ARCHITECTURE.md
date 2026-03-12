# ProcuraX Backend Architecture

## 📁 Project Structure

```
procurax_backend/
├── api/                    # API versioned routes
│   └── v1/                 # Version 1 API
│       ├── index.js        # Route aggregator
│       ├── tasks.routes.js # Task endpoints
│       ├── notes.routes.js # Note endpoints
│       └── meetings.routes.js # Meeting endpoints
│
├── core/                   # Core infrastructure
│   ├── errors/             # Error handling
│   │   └── AppError.js     # Custom error class
│   ├── middleware/         # Shared middleware
│   │   ├── auth.middleware.js      # Unified authentication
│   │   ├── errorHandler.js         # Global error handler
│   │   ├── httpLogger.middleware.js # Request logging
│   │   ├── rateLimiter.middleware.js # Rate limiting
│   │   └── requestId.middleware.js # Correlation IDs
│   ├── validation/         # Input validation
│   │   ├── schemas.js      # Joi validation schemas
│   │   └── validate.middleware.js  # Validation middleware
│   ├── services/           # Business logic layer
│   │   ├── task.service.js
│   │   ├── note.service.js
│   │   └── meeting.service.js
│   ├── logging/            # Winston logging
│   │   └── logger.js
│   ├── config/             # Configuration
│   │   └── envValidator.js # Environment validation
│   └── index.js            # Central export
│
├── tests/                  # Test suites
│   ├── setup.js            # Jest configuration
│   └── unit/               # Unit tests
│       └── task.service.test.js
│
├── logs/                   # Log files (production)
│   └── .gitkeep
│
└── [existing modules...]   # Tasks, Notes, Meetings, Auth, etc.
```

## 🏗️ Architecture Improvements

### 1. Centralized Error Handling

```javascript
import { AppError } from './core/index.js';

// Create specific errors
throw AppError.notFound("Task");
throw AppError.badRequest("Invalid input", { field: "title" });
throw AppError.validation([{ field: "email", message: "Invalid format" }]);
throw AppError.unauthorized("Token expired");
```

### 2. Unified Authentication

```javascript
import { 
  authMiddleware, 
  adminMiddleware, 
  requireRole 
} from './core/index.js';

// Standard user authentication
router.get("/tasks", authMiddleware, getTasksController);

// Admin-only routes
router.delete("/users/:id", adminMiddleware, deleteUserController);

// Role-based access
router.post("/reports", authMiddleware, requireRole("admin", "manager"), createReportController);
```

### 3. Input Validation with Joi

```javascript
import { validateBody, taskSchemas } from './core/index.js';

router.post(
  "/tasks",
  authMiddleware,
  validateBody(taskSchemas.create),
  createTaskController
);
```

### 4. Rate Limiting

```javascript
import { authLimiter, apiLimiter } from './core/index.js';

// Strict rate limiting for auth endpoints
router.post("/login", authLimiter, loginController);

// Standard rate limiting for API
app.use("/api", apiLimiter);
```

### 5. Service Layer Pattern

```javascript
import { TaskService } from './core/index.js';

// In controller
const createTaskController = async (req, res, next) => {
  try {
    const task = await TaskService.createTask(req.body, req.userId);
    res.status(201).json({ success: true, task });
  } catch (error) {
    next(error);
  }
};
```

### 6. Structured Logging

```javascript
import { logger } from './core/index.js';

logger.info("Task created", { taskId: task._id, userId: req.userId });
logger.warn("Rate limit exceeded", { ip: req.ip, path: req.path });
logger.error("Database error", { error: err.message, requestId: req.id });
```

### 7. Request Correlation IDs

Every request receives a unique ID for tracing:

```javascript
// Automatically added by requestIdMiddleware
// Available as req.id in all handlers
// Returned in X-Request-Id response header
```

### 8. Environment Validation

Validates required env vars at startup:

```javascript
import { validateEnvironment } from './core/index.js';

// In app.js
validateEnvironment(); // Fails fast if critical config missing
```

## 🔄 API Versioning

All new routes should use versioned endpoints:

```
/api/v1/tasks
/api/v1/notes
/api/v1/meetings
```

Legacy routes remain at `/api/*` for backward compatibility.

## 🧪 Testing

Run tests:

```bash
npm test
npm run test:coverage
```

## 📦 New Dependencies

- `joi` - Schema validation
- `winston` - Structured logging
- `express-rate-limit` - Rate limiting
- `uuid` - Request correlation IDs

## 🚀 Usage in app.js

```javascript
import {
  errorHandler,
  notFoundHandler,
  requestIdMiddleware,
  httpLogger,
  validateEnvironment,
  apiLimiter,
} from './core/index.js';

import v1Routes from './api/v1/index.js';

// Validate environment at startup
validateEnvironment();

// Apply middleware
app.use(requestIdMiddleware);
app.use(httpLogger);
app.use("/api/v1", apiLimiter, v1Routes);

// Error handling (must be last)
app.use(notFoundHandler);
app.use(errorHandler);
```

## 📈 Benefits

1. **Consistent error responses** across all endpoints
2. **Type-safe validation** with detailed error messages
3. **Centralized authentication** - single source of truth
4. **Request tracing** with correlation IDs
5. **Structured logging** for debugging and monitoring
6. **Rate limiting** protection against abuse
7. **Service layer** separates business logic from HTTP
8. **Testable code** with proper separation of concerns
