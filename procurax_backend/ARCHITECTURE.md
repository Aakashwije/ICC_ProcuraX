# ProcuraX Backend — Architecture & Engineering Documentation

> Full-stack procurement management system.  
> **Backend**: Node.js 22 · Express 5 · MongoDB 8 / Mongoose · JWT auth  
> **Frontend**: Flutter / Dart · Provider state management  

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Project Structure](#2-project-structure)
3. [Layered Architecture Design](#3-layered-architecture-design)
4. [Middleware Pipeline](#4-middleware-pipeline)
5. [Service Layer Pattern](#5-service-layer-pattern)
6. [Authentication & Authorisation](#6-authentication--authorisation)
7. [Error Handling Strategy](#7-error-handling-strategy)
8. [Input Validation](#8-input-validation)
9. [API Versioning](#9-api-versioning)
10. [Scalability & Performance](#10-scalability--performance)
11. [Logging & Observability](#11-logging--observability)
12. [Testing Strategy](#12-testing-strategy)
13. [Security Measures](#13-security-measures)
14. [Design Decisions & Justifications](#14-design-decisions--justifications)
15. [Dependencies](#15-dependencies)
16. [Running the Project](#16-running-the-project)

---

## 1. Architecture Overview

ProcuraX uses a **three-tier layered architecture** designed around Separation of Concerns (SoC):

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter Client                           │
│  (Provider state management, Repository pattern, REST calls)    │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTPS / REST
┌────────────────────────────▼────────────────────────────────────┐
│                     Express HTTP Server                          │
│                                                                  │
│   Request  ──►  Middleware Pipeline  ──►  Router  ──►  Response  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Presentation Layer (Routes / Controllers)               │   │
│  │  - Thin controllers: parse req ➜ call service ➜ send res │   │
│  │  - Input validation via Joi middleware                    │   │
│  └──────────────────────────────┬───────────────────────────┘   │
│                                  │                               │
│  ┌──────────────────────────────▼───────────────────────────┐   │
│  │  Business Logic Layer (Services)                         │   │
│  │  - TaskService, NoteService, MeetingService,             │   │
│  │    ProjectService, NotificationService                   │   │
│  │  - Pure business rules, no HTTP knowledge                │   │
│  └──────────────────────────────┬───────────────────────────┘   │
│                                  │                               │
│  ┌──────────────────────────────▼───────────────────────────┐   │
│  │  Data Access Layer (Mongoose Models)                     │   │
│  │  - Task, Note, Meeting, Project, User, Notification      │   │
│  │  - Schema definitions, indexes, virtual fields           │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Cross-Cutting Concerns (core/)                          │   │
│  │  - Error handling, logging, auth, rate-limiting,         │   │
│  │    caching, validation, request tracing                  │   │
│  └──────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
                             │
              ┌──────────────▼──────────────┐
              │      MongoDB (Atlas)         │
              │  - Replica set for HA        │
              │  - Indexed collections       │
              └─────────────────────────────┘
```

**Why three tiers?**  Controllers never touch the database directly. Services never construct HTTP responses. This makes each layer independently testable and replaceable.

---

## 2. Project Structure

```
procurax_backend/
├── api/                          # Versioned API routes
│   └── v1/
│       ├── index.js              # Route aggregator (mounts all v1 routes)
│       ├── tasks.routes.js       # /api/v1/tasks
│       ├── notes.routes.js       # /api/v1/notes
│       ├── meetings.routes.js    # /api/v1/meetings
│       ├── notifications.routes.js # /api/v1/notifications
│       └── projects.routes.js    # /api/v1/projects
│
├── core/                         # ★ Core infrastructure (reusable across modules)
│   ├── errors/
│   │   └── AppError.js           # Custom error class with factory methods
│   ├── middleware/
│   │   ├── auth.middleware.js    # Unified JWT auth + RBAC
│   │   ├── errorHandler.js       # Global error handler + asyncHandler
│   │   ├── httpLogger.middleware.js  # Request/response logging
│   │   ├── rateLimiter.middleware.js # Tiered rate limiters
│   │   └── requestId.middleware.js   # UUID correlation IDs
│   ├── validation/
│   │   ├── schemas.js            # Joi schemas for all entities
│   │   └── validate.middleware.js # validateBody/Query/Params/ObjectId
│   ├── services/
│   │   ├── task.service.js       # Task business logic
│   │   ├── note.service.js       # Note business logic
│   │   ├── meeting.service.js    # Meeting business logic
│   │   ├── project.service.js    # Project business logic
│   │   ├── notification.service.js # Notification CRUD
│   │   ├── cache.service.js      # In-memory TTL cache
│   │   └── jobQueue.js           # Async background job queue
│   ├── logging/
│   │   └── logger.js             # Winston structured logger
│   ├── config/
│   │   └── envValidator.js       # Startup environment checks
│   └── index.js                  # Central barrel export
│
├── tests/                        # Test suites
│   ├── setup.js                  # Jest environment config
│   └── unit/
│       ├── task.service.test.js   # TaskService + AppError tests
│       ├── note.service.test.js   # NoteService tests
│       ├── auth.middleware.test.js # Auth + RBAC tests
│       ├── middleware.test.js     # ErrorHandler + Cache + JobQueue tests
│       └── validation.test.js    # Joi validation middleware tests
│
├── tasks/                        # Task module
├── notes/                        # Notes module
├── notifications/                # Notifications module
├── meetings/                     # Meetings module
├── admin-api/                    # Admin panel API
├── settings/                     # User settings
├── config/                       # App configuration (db, jwt, firebase)
├── models/                       # Shared Mongoose models
├── app.js                        # Application entry point
├── jest.config.js                # Jest configuration
└── package.json
```

---

## 3. Layered Architecture Design

### Data Flow (Create Task Example)

```
Client POST /api/v1/tasks
        │
        ▼
┌─ requestIdMiddleware ──► req.id = "uuid-1234"
├─ httpLogger            ──► logs: "POST /api/v1/tasks"
├─ cors                  ──► CORS headers
├─ express.json()        ──► parses body
├─ apiLimiter            ──► 100 req / 15 min
│
├─ authMiddleware        ──► JWT ➜ req.userId, req.userRole
├─ validateBody(schema)  ──► Joi ➜ req.validatedBody
│
├─ tasksController.createTask
│    │   // Thin: just orchestrates
│    ├── TaskService.createTask(data, userId)
│    │     ├── new Task(data).save()     ← Mongoose
│    │     └── return normalizeTask(task)
│    ├── res.status(201).json({ success, task })
│    └── NotificationService.create(...)  ← fire-and-forget
│
├─ errorHandler          ──► catches any thrown errors
└──► 201 { success: true, task: { ... } }
```

### Controller → Service Contract

```javascript
// Controller: HTTP in, HTTP out
const createTask = asyncHandler(async (req, res) => {
  const task = await TaskService.createTask(req.body, req.userId);
  res.status(201).json({ success: true, task });
});

// Service: pure business logic, no HTTP awareness
class TaskService {
  async createTask(data, userId) {
    const task = new Task({ ...data, owner: userId });
    await task.save();
    return this.normalizeTask(task);
  }
}
```

---

## 4. Middleware Pipeline

Middleware is applied **in order** in `app.js`. The order matters:

```javascript
// 1. Request tracing — must be first
app.use(requestIdMiddleware);

// 2. HTTP logging — logs every request
app.use(httpLogger);

// 3. CORS — before any route handling
app.use(cors({ origin: true, credentials: true }));

// 4. Body parsing
app.use(express.json({ limit: "10mb" }));

// 5. Rate limiting — before route matching
app.use("/api/", apiLimiter);        // 100 req / 15 min
app.use("/api/auth/", authLimiter);  // 5 req / 15 min

// 6. Routes
app.use("/api/v1", v1Routes);
app.use("/api/tasks", taskRoutes);   // Legacy compatibility
// ... more routes

// 7. 404 handler — after all routes
app.use(notFoundHandler);

// 8. Global error handler — must be last middleware
app.use(errorHandler);
```

| Middleware | Purpose | Configuration |
|---|---|---|
| `requestIdMiddleware` | Adds UUID `req.id`, returns `X-Request-Id` header | Auto-generated per request |
| `httpLogger` | Winston HTTP request/response logging | Logs method, path, status, duration |
| `apiLimiter` | Rate limits API routes | 100 requests / 15 minutes |
| `authLimiter` | Strict limit on login/register | 5 requests / 15 minutes |
| `authMiddleware` | JWT verification, attaches `req.userId` | `Authorization: Bearer <token>` |
| `adminMiddleware` | Admin-only access (role check) | Requires `role: "admin"` in JWT |
| `validateBody(schema)` | Joi body validation | Per-route schema |
| `errorHandler` | Catches all errors, returns JSON | Dev: stack trace. Prod: safe message |

---

## 5. Service Layer Pattern

Each domain entity has a dedicated service class.

| Service | Responsibilities |
|---|---|
| `TaskService` | CRUD, archive/restore, stats aggregation, normalisation |
| `NoteService` | CRUD, tag management, pagination |
| `MeetingService` | CRUD, conflict detection, mark-done |
| `ProjectService` | CRUD, manager assignment, status tracking |
| `NotificationService` | CRUD, read/unread management, stats |
| `CacheService` | In-memory TTL cache, prefix invalidation |
| `JobQueue` | Async background job processing with retry |

**Design rule**: Services are singletons exported as class instances. They:
- Accept plain JavaScript objects (not `req`)
- Throw `AppError` instances on failure
- Return normalised plain objects (not Mongoose documents)
- Log via Winston (not `console.log`)

---

## 6. Authentication & Authorisation

### Unified Auth Middleware (`core/middleware/auth.middleware.js`)

**Single source of truth** for all JWT operations. Replaces 6 previously duplicated auth files:

```
Before (duplicated):           After (unified):
├── auth/auth.middleware.js    ├── core/middleware/auth.middleware.js
├── auth/middleware/auth...    │   ├── authMiddleware
├── auth/middleware/admin...   │   ├── adminMiddleware
├── admin-api/middleware/...   │   ├── requireRole(...roles)
├── media/middleware/auth...   │   ├── optionalAuth
├── settings/authMiddleware    │   ├── generateToken(userId, role)
└── meetings/middleware/...    │   └── verifyToken(token)
```

### Role-Based Access Control (RBAC)

```javascript
// Flexible role checking
router.post("/reports",
  authMiddleware,
  requireRole("admin", "project_manager"),
  createReport
);
```

**JWT Payload**:
```json
{
  "id": "user_mongo_id",
  "role": "project_manager",
  "iat": 1710000000,
  "exp": 1710604800
}
```

---

## 7. Error Handling Strategy

### AppError Class Hierarchy

```
Error (built-in)
 └── AppError (custom)
      ├── .statusCode    (HTTP status)
      ├── .errorCode     (machine-readable)
      ├── .message       (human-readable)
      ├── .isOperational (safe to show client?)
      ├── .details       (validation errors array)
      └── .toJSON()      (standardised response)
```

### Factory Methods

| Method | Status | Use Case |
|---|---|---|
| `AppError.badRequest(msg)` | 400 | Invalid input |
| `AppError.unauthorized(msg)` | 401 | Missing/invalid token |
| `AppError.forbidden(msg)` | 403 | Insufficient permissions |
| `AppError.notFound(entity)` | 404 | Resource not found |
| `AppError.conflict(msg)` | 409 | Duplicate entry |
| `AppError.validation(errors)` | 422 | Schema validation failure |
| `AppError.internal(msg)` | 500 | Server error |

### Response Format

```json
{
  "success": false,
  "error": {
    "code": "NOT_FOUND",
    "message": "Task not found",
    "details": null,
    "timestamp": "2024-01-15T10:30:00.000Z",
    "requestId": "a1b2c3d4-e5f6-7890"
  }
}
```

In **development**, stack traces are included. In **production**, only `isOperational` errors expose their messages; unknown errors return a generic "Something went wrong" to avoid leaking internals.

---

## 8. Input Validation

### Joi Schema Validation

All API inputs are validated before reaching controllers:

```javascript
// Route definition
router.post("/tasks",
  authMiddleware,
  validateBody(taskSchemas.create),   // ← Validates + strips unknown fields
  createTaskController
);
```

**Schemas defined for**: auth (login/register), tasks (create/update), notes, meetings, projects, notifications, users, pagination queries.

### Validation Middleware Types

| Middleware | Validates | Attaches |
|---|---|---|
| `validateBody(schema)` | `req.body` | `req.validatedBody` |
| `validateQuery(schema)` | `req.query` | `req.validatedQuery` |
| `validateParams(schema)` | `req.params` | `req.validatedParams` |
| `validateObjectId(param)` | MongoDB ObjectId format | — |

**Security feature**: `stripUnknown: true` removes any fields not in the schema, preventing mass-assignment attacks.

---

## 9. API Versioning

### Strategy: URI Path Versioning

```
/api/v1/tasks          ← Current version
/api/v1/notes
/api/v1/meetings
/api/v1/notifications
/api/v1/projects

/api/tasks             ← Legacy (maintained for backward compat)
```

**Why URI versioning?** Simpler to implement, visible in logs/URLs, easy to deprecate. Header-based versioning (`Accept: application/vnd.api.v1+json`) was considered but adds complexity without proportional benefit for this project's scale.

### Route Aggregator

```javascript
// api/v1/index.js — single mount point
import taskRoutes from "./tasks.routes.js";
import noteRoutes from "./notes.routes.js";
// ...

const router = Router();
router.use("/tasks", taskRoutes);
router.use("/notes", noteRoutes);
// ...

export default router;
```

New versions (v2) can be added as a separate folder with different middleware without modifying v1.

---

## 10. Scalability & Performance

### Current Architecture (Vertical Scaling)

| Component | Implementation | Production Replacement |
|---|---|---|
| **Cache** | In-memory `Map` with TTL | Redis (shared across instances) |
| **Job Queue** | In-process async queue | Bull + Redis / AWS SQS |
| **Sessions** | JWT (stateless) | Already horizontally scalable |
| **Database** | MongoDB single instance | MongoDB Atlas replica set |
| **Rate Limiter** | In-memory store | Redis-backed store |

### Cache Service

```javascript
// In-memory TTL cache reduces DB reads
CacheService.set("tasks:user123", taskList, 300); // 5-min TTL
CacheService.get("tasks:user123");                  // cache hit
CacheService.invalidatePrefix("tasks:user123");     // on write
```

Features:
- Configurable TTL per entry (default 5 minutes)
- Prefix-based invalidation (clear all of a user's cache)
- Hit-rate statistics for monitoring
- Periodic cleanup of expired entries (every 60s)
- Express middleware for automatic GET response caching

### Job Queue

```javascript
// Async background processing (notifications, emails)
jobQueue.registerHandler("notification", async (payload) => {
  await Notification.create(payload);
});

jobQueue.enqueue("notification", { userId, type, message });
```

Features:
- Priority ordering (high → normal → low)
- Exponential backoff retries (max 3 attempts)
- Job statistics (enqueued, processed, failed)
- Handler registration pattern

### Horizontal Scaling Path

```
                    ┌─────────────────────┐
                    │   Load Balancer      │
                    │  (nginx / ALB)       │
                    └─────┬───────┬───────┘
                          │       │
              ┌───────────▼───┐ ┌─▼───────────┐
              │  Node.js #1   │ │  Node.js #2  │
              │  (Express)    │ │  (Express)   │
              └───────┬───┬──┘ └──┬───┬───────┘
                      │   │       │   │
              ┌───────▼───▼───────▼───▼───────┐
              │           Redis                │
              │  (Cache + Rate Limit + Queue)  │
              └───────────────┬───────────────┘
                              │
              ┌───────────────▼───────────────┐
              │       MongoDB Atlas            │
              │    (Replica Set + Sharding)    │
              └───────────────────────────────┘
```

The code is structured so that swapping `CacheService` for a Redis client and `JobQueue` for Bull requires changes in **only one file each** — no business logic changes needed.

---

## 11. Logging & Observability

### Winston Structured Logging

```javascript
// All logs include requestId for correlation
logger.info("Task created", { taskId, userId, requestId: req.id });
logger.warn("Rate limit hit", { ip: req.ip, path: req.path });
logger.error("DB connection failed", { error: err.message });
```

### Log Levels

| Level | When | Example |
|---|---|---|
| `error` | Application errors, unhandled exceptions | DB failure, crash |
| `warn` | Recoverable issues, security events | Rate limit, auth failure |
| `info` | Normal operations | Task created, user login |
| `debug` | Development detail | Query params, cache hits |

### Request Tracing

Every HTTP request gets a UUID correlation ID:

```
Request:  X-Request-Id: a1b2c3d4-e5f6-7890-abcd-ef1234567890
Response: X-Request-Id: a1b2c3d4-e5f6-7890-abcd-ef1234567890
Logs:     [a1b2c3d4] POST /api/v1/tasks 201 45ms
```

This allows tracing a single request through all log entries.

---

## 12. Testing Strategy

### Test Architecture

```
tests/
├── setup.js                    # Environment variables, timeouts
└── unit/
    ├── task.service.test.js    # 23 tests — TaskService + AppError
    ├── note.service.test.js    # 12 tests — NoteService
    ├── auth.middleware.test.js # 13 tests — JWT auth + RBAC
    ├── middleware.test.js      # 18 tests — ErrorHandler + Cache + JobQueue
    └── validation.test.js      # 12 tests — Joi validation middleware
                               ──────────
                                77 tests total
```

### Mocking Strategy (ESM-compatible)

```javascript
// jest.unstable_mockModule for ESM
jest.unstable_mockModule("../../tasks/tasks.model.js", () => ({
  default: MockTaskConstructor,
}));

const { default: TaskService } = await import("../../core/services/task.service.js");
```

**Why ESM mocking?** The project uses `"type": "module"` in package.json. Jest's `jest.mock()` doesn't work with ESM; `jest.unstable_mockModule()` + dynamic `import()` is required.

### Test Categories

| Category | What's Tested | Coverage |
|---|---|---|
| **Service Layer** | Business logic, CRUD, error cases | TaskService, NoteService |
| **Middleware** | Error handling, cache, job queue | errorHandler, asyncHandler, CacheService, JobQueue |
| **Authentication** | JWT verify, RBAC, token generation | authMiddleware, adminMiddleware, requireRole |
| **Validation** | Joi schemas, ObjectId format | validateBody, validateQuery, validateObjectId |
| **Error Classes** | Factory methods, serialisation | AppError.badRequest/notFound/validation etc. |

### Running Tests

```bash
npm test                    # Run all tests with ESM support
npm run test:watch          # Watch mode
npm run test:coverage       # Generate coverage report
```

---

## 13. Security Measures

| Measure | Implementation | Location |
|---|---|---|
| **JWT Authentication** | Bearer token with expiry | `core/middleware/auth.middleware.js` |
| **Rate Limiting** | Tiered per endpoint type | `core/middleware/rateLimiter.middleware.js` |
| **Input Validation** | Joi schemas, strip unknown | `core/validation/` |
| **CORS** | Origin whitelist | `app.js` |
| **Error Masking** | No stack traces in production | `core/middleware/errorHandler.js` |
| **Body Size Limit** | 10MB JSON limit | `app.js` |
| **Password Hashing** | bcrypt with salt rounds | `bcryptjs` |
| **ObjectId Validation** | Regex check before DB query | `validateObjectId` middleware |

---

## 14. Design Decisions & Justifications

### Why Express 5 over Koa / Fastify?

Express 5 adds native async error handling (`app.use(async (req, res) => {...})`) and removes legacy baggage. It has the largest middleware ecosystem and team familiarity.

### Why Mongoose over raw MongoDB driver?

Schema definitions provide built-in validation, middleware hooks, and virtual fields. The overhead is negligible for this application's scale. Migrations to the raw driver are possible since services return plain objects, not Mongoose documents.

### Why in-memory cache instead of Redis?

For a single-server coursework deployment, an in-memory `Map` provides the same performance benefits (reduced DB load) without requiring an additional infrastructure dependency. The `CacheService` is designed with the same API surface as a Redis cache, making the swap trivial for production.

### Why Joi over Zod / Yup?

Joi has the most mature Express integration, comprehensive type coercion (string query params → numbers), and the clearest error message formatting. Zod was considered but has a steeper learning curve for Express middleware integration.

### Why a job queue for notifications?

Notification creation is a side-effect of task/meeting/project operations. Making it synchronous would slow down primary operations. Fire-and-forget queueing keeps response times low while guaranteeing delivery through retries.

### Why singleton services?

Services are stateless by design — they receive all data through method parameters. A single instance per service avoids unnecessary object creation and aligns with the module pattern (`export default new TaskService()`).

---

## 15. Dependencies

### Production

| Package | Version | Purpose |
|---|---|---|
| `express` | ^5.2.1 | HTTP server framework |
| `mongoose` | ^8.12.1 | MongoDB ODM |
| `jsonwebtoken` | ^9.0.3 | JWT authentication |
| `bcryptjs` | ^3.0.3 | Password hashing |
| `joi` | ^18.0.2 | Schema validation |
| `winston` | ^3.x | Structured logging |
| `express-rate-limit` | ^8.3.1 | API rate limiting |
| `uuid` | ^11.x | Request correlation IDs |
| `cors` | ^2.8.6 | Cross-origin requests |
| `dotenv` | ^17.x | Environment config |
| `multer` | ^2.0.2 | File uploads |

### Development

| Package | Version | Purpose |
|---|---|---|
| `jest` | ^30.x | Testing framework |
| `nodemon` | ^3.x | Auto-restart in dev |

---

## 16. Running the Project

```bash
# Install dependencies
npm install

# Development (auto-restart)
npm run dev

# Production
npm start

# Run tests
npm test

# Test with coverage
npm run test:coverage

# Health check
curl http://localhost:5000/health
```

### Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `MONGODB_URI` | Yes | — | MongoDB connection string |
| `JWT_SECRET` | Yes | `change_me` | JWT signing key |
| `JWT_EXPIRE` | No | `7d` | Token expiry |
| `PORT` | No | `5000` | Server port |
| `NODE_ENV` | No | `development` | Environment mode |
| `FIREBASE_*` | No | — | Push notification config |
