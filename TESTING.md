# Testing & Quality Assurance Documentation

## ProcuraX — Comprehensive Test Plan

---

## Table of Contents

1. [Testing Strategy Overview](#testing-strategy-overview)
2. [Test Architecture](#test-architecture)
3. [Test Categories](#test-categories)
4. [Backend Testing](#backend-testing)
5. [Frontend Testing](#frontend-testing)
6. [Non-Functional Testing](#non-functional-testing)
7. [CI/CD Pipeline](#cicd-pipeline)
8. [Running Tests](#running-tests)
9. [Coverage Targets](#coverage-targets)
10. [Test Evidence](#test-evidence)

---

## Testing Strategy Overview

ProcuraX follows a **multi-layered testing strategy** aligned with the testing pyramid:

```
            ╱╲
           ╱  ╲         E2E / Manual
          ╱────╲
         ╱      ╲       Integration Tests
        ╱────────╲
       ╱          ╲     Non-Functional (Security + Performance)
      ╱────────────╲
     ╱              ╲   Unit Tests (largest layer)
    ╱────────────────╲
```

| Layer | Count | Tool | Location |
|-------|-------|------|----------|
| Unit Tests (Backend) | ~210 | Jest 30.3 + ESM | `tests/unit/` |
| Integration Tests | ~17 | Jest | `tests/integration/` |
| Security Tests | ~19 | Jest | `tests/security/` |
| Performance Tests | ~14 | Jest | `tests/performance/` |
| Unit Tests (Frontend) | ~85 | flutter_test | `test/` |
| **Total** | **~345** | | |

---

## Test Architecture

### Backend (Node.js / Express / MongoDB)

```
procurax_backend/
├── jest.config.js           # Jest configuration (ESM, coverage, thresholds)
├── tests/
│   ├── setup.js             # Environment bootstrapping
│   ├── unit/
│   │   ├── task.service.test.js          # 23 tests — CRUD + stats
│   │   ├── note.service.test.js          # 12 tests — CRUD + pagination
│   │   ├── auth.middleware.test.js        # 13 tests — JWT + RBAC
│   │   ├── middleware.test.js            # 18 tests — error handler, cache, jobs
│   │   ├── validation.test.js            # 12 tests — Joi schemas, ObjectId
│   │   ├── notification.service.test.js  # 16 tests — notifications CRUD + stats
│   │   ├── meeting.service.test.js       # 16 tests — meetings CRUD + conflicts
│   │   ├── procurement.service.test.js   # 15 tests — sheet parsing, caching, status
│   │   ├── communication.test.js         # 18 tests — chat, messages, alerts (Firestore)
│   │   ├── media.test.js                 # 14 tests — document schema, file filter, CRUD
│   │   ├── auth.controller.test.js       # 20 tests — register, login, password reset
│   │   ├── settings.test.js              # 16 tests — settings CRUD, defaults, merge
│   │   ├── buildassist.test.js           # 12 tests — NLP, intent detection, AI chat
│   │   └── user.test.js                  # 15 tests — profile, JWT extraction, schema
│   ├── integration/
│   │   └── api.integration.test.js       # 17 tests — auth flow, error format, workflows
│   ├── security/
│   │   └── security.test.js              # 19 tests — JWT, XSS, NoSQL injection, rate limiting
│   └── performance/
│       └── performance.test.js           # 14 tests — benchmarks, pagination, concurrency
```

### Frontend (Flutter / Dart)

```
procurax_frontend/
├── test/
│   ├── widget_test.dart                  # Widget rendering tests
│   ├── models/
│   │   ├── task_model_test.dart           # 20 tests — fromJson, toJson, copyWith, enums
│   │   ├── note_model_test.dart           # 15 tests — fromJson, toJson, copyWith, round-trip
│   │   ├── procurement_model_test.dart    # 18 tests — ProcurementItem/View/Delivery fromJson
│   │   ├── meeting_model_test.dart        # 16 tests — Meeting fromJson, toJson, copyWith, timeRange
│   │   └── alert_model_test.dart          # 30 tests — AlertModel, enums, timeAgo, copyWith
│   ├── settings/
│   │   └── theme_notifier_test.dart       # 6 tests — ThemeNotifier, dark/light switch, listeners
│   └── services/
│       └── auth_service_test.dart         # 11 tests — PasswordResetException, error codes, helpers
```

---

## Test Categories

### 1. Unit Tests

Unit tests verify individual functions, services, and methods **in isolation** using mocked dependencies.

**Mocking Pattern (ESM):**
```javascript
jest.unstable_mockModule("../../models/Task.js", () => ({
  default: MockTaskConstructor,
}));
const { TaskService } = await import("../../core/services/task.service.js");
```

**Modules Covered:**
- ✅ Task Service — full CRUD lifecycle, statistics, normalisation
- ✅ Note Service — full CRUD, pagination, tag filtering
- ✅ Auth Middleware — JWT verification, role checks, token expiry
- ✅ Core Middleware — error handler, cache, async job queue
- ✅ Validation — Joi schema validation, ObjectId format checks
- ✅ Notification Service — CRUD, markAllRead, stats aggregation
- ✅ Meeting Service — CRUD, conflict detection, upcoming meetings
- ✅ Procurement Service — Google Sheets parsing, status calculation, caching, filtering
- ✅ Communication — Chat creation, messages, alerts (Firestore mocks)
- ✅ Media / Documents — Mongoose schema, file filter (MIME types), multer storage, CRUD
- ✅ Auth Controller — register, login (validation, approval gate), password reset helpers
- ✅ Settings — settings CRUD, default creation, partial merge updates
- ✅ BuildAssist — NLP token parsing, intent detection, AI chat response formatting
- ✅ User — JWT extraction, getUserProfile, safe field selection

### 2. Integration Tests

Integration tests verify the interaction between **multiple layers** (routing → middleware → serialisation).

**Tests Cover:**
- JWT authentication flow (valid, expired, tampered, wrong-secret tokens)
- Error response format conformance (AppError serialisation)
- CRUD workflow simulations (task lifecycle, notification lifecycle)
- Meeting conflict detection logic

### 3. Security Tests (Non-Functional)

**Tests Cover:**
- JWT algorithm confusion attacks (none algorithm bypass)
- JWT payload tampering detection
- NoSQL injection pattern detection (`$gt`, `$ne`, `$regex`, `$where`)
- XSS payload sanitisation (`<script>`, `<img onerror>`, `<svg onload>`)
- ObjectId format validation (injection prevention)
- Input length validation
- Email format validation
- Password complexity requirements
- Sensitive data leak prevention in error responses
- Rate limiting configuration validation

### 4. Performance Tests (Non-Functional)

**Tests Cover:**
- In-memory sort of 10,000 items (< 50ms benchmark)
- In-memory filter of 50,000 items (< 20ms benchmark)
- Large response JSON serialisation (< 10ms benchmark)
- JSON deserialisation (< 5ms benchmark)
- Pagination efficiency (correctness + timing)
- Concurrent promise resolution (100 parallel requests)
- Mixed success/failure batch handling
- Memory efficiency (Map vs Array lookup O(1) vs O(n))

### 5. Frontend Unit Tests

**Tests Cover:**
- **Task Model:**
  - Enum parsing (TaskPriority: low, medium, high, critical)
  - Enum parsing (TaskStatus: todo, in_progress, blocked, done)
  - `fromJson` with complete data, missing fields, null handling
  - `copyWith` immutability and field updates
  - `completed` getter logic
  - `toCreateJson` and `toUpdateJson` serialisation
  - Date parsing edge cases (null, empty, invalid strings)
  
- **Note Model:**
  - `fromJson` with complete data, missing fields, ID variants
  - Default tag fallback to "Issue"
  - `copyWith` immutability
  - `toJson` output format and date serialisation
  - Round-trip serialisation fidelity

- **Procurement Model:**
  - `ProcurementItem.fromJson` — 9 fields, null handling, empty JSON
  - `ProcurementView.fromJson` — nested lists of ProcurementItemView + DeliverySimpleView
  - `ProcurementItemView.fromJson` — full logistics fields
  - `DeliverySimpleView.fromJson` — summary fields with status

- **Meeting Model:**
  - `fromJson` — date parsing (UTC → local), `_id` / `id` fallback, `isDone` boolean
  - `toJson` — UTC ISO 8601 serialisation, `isDone` field
  - `copyWith` — partial immutable updates, all fields
  - `timeRange` getter — formatted string with 30-minute padding

- **Alert / Notification Model:**
  - `AlertType` enum — 7 values + unknown fallback to general
  - `AlertPriority` enum — 4 values + unknown fallback to medium
  - `ProjectStatus` enum — 5 values parsing
  - `AlertModel.fromJson` — complete JSON, `_id`/`id` fallback, `_extractId` (String/Map/null), metadata, timestamp parsing/fallback
  - `AlertModel.toJson` — conditional field inclusion (null omission)
  - `AlertModel.copyWith` — 16 fields immutable update
  - `AlertModel.timeAgo` — relative time formatting (Just now, m, h, d, w, mo)

- **Theme Notifier (Settings):**
  - Default light mode, `setTheme("Dark")` → dark, `setTheme("Light")` → light
  - Non-"Dark" strings default to light mode
  - `notifyListeners` called on every `setTheme` call

- **Auth Service (PasswordResetException):**
  - Factory `fromResponse` — parses code, message, attemptsRemaining, retryAfter, requirements
  - Default fallbacks for missing fields (code → UNKNOWN, message → "Something went wrong")
  - Boolean helpers: `isLocked`, `isRateLimited`, `isExpired`, `isInvalidOTP`, `isWeakPassword`, `isSamePassword`
  - `toString()` returns human-readable message

---

## CI/CD Pipeline

The project uses **GitHub Actions** for continuous integration:

**File:** `.github/workflows/ci.yml`

### Pipeline Stages

```
┌─────────────────┐    ┌──────────────────┐
│ Backend Tests    │    │ Frontend Tests   │
│ (Node 18 & 20)  │    │ (Flutter 3.29)   │
│                  │    │                  │
│ • Unit           │    │ • flutter analyze│
│ • Integration    │    │ • flutter test   │
│ • Security       │    │ • Coverage       │
│ • Performance    │    │                  │
│ • Coverage       │    │                  │
└────────┬─────────┘    └────────┬─────────┘
         │                       │
         └───────────┬───────────┘
                     │
          ┌──────────▼──────────┐
          │  Code Quality Gate  │
          │  • Coverage reports │
          │  • Summary          │
          └─────────────────────┘
```

### Triggers
- Push to `main` or `develop`
- Pull requests to `main` or `develop`

### Artifacts
- Backend coverage report (30-day retention)
- Frontend coverage report (30-day retention)

---

## Running Tests

### Backend Tests

```bash
cd procurax_backend

# Run all tests
npm test

# Run by category
npm run test:unit          # Unit tests only
npm run test:integration   # Integration tests only
npm run test:security      # Security tests only
npm run test:performance   # Performance tests only

# Coverage
npm run test:coverage      # All tests with coverage report

# Watch mode (development)
npm run test:watch

# CI mode (with coverage + force exit)
npm run test:ci
```

### Frontend Tests

```bash
cd procurax_frontend

# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/models/task_model_test.dart
flutter test test/models/note_model_test.dart
flutter test test/models/procurement_model_test.dart
flutter test test/models/meeting_model_test.dart
flutter test test/models/alert_model_test.dart
flutter test test/settings/theme_notifier_test.dart
flutter test test/services/auth_service_test.dart

# Run with verbose output
flutter test --reporter expanded
```

---

## Coverage Targets

| Metric | Target | Rationale |
|--------|--------|-----------|
| Line Coverage | ≥ 60% | Core business logic fully tested |
| Function Coverage | ≥ 50% | All service methods have test cases |
| Branch Coverage | ≥ 50% | Edge cases and error paths tested |
| Statement Coverage | ≥ 60% | Critical code paths executed |

Coverage thresholds are enforced in `jest.config.js`:
```javascript
coverageThresholds: {
  global: {
    branches: 50,
    functions: 50,
    lines: 60,
    statements: 60,
  },
},
```

---

## Test Evidence

### Backend Test Execution

After running `npm test`, expect output similar to:

```
PASS  tests/unit/task.service.test.js (23 tests)
PASS  tests/unit/note.service.test.js (12 tests)
PASS  tests/unit/auth.middleware.test.js (13 tests)
PASS  tests/unit/middleware.test.js (18 tests)
PASS  tests/unit/validation.test.js (12 tests)
PASS  tests/unit/notification.service.test.js (16 tests)
PASS  tests/unit/meeting.service.test.js (16 tests)
PASS  tests/unit/procurement.service.test.js (15 tests)
PASS  tests/unit/communication.test.js (18 tests)
PASS  tests/unit/media.test.js (14 tests)
PASS  tests/unit/auth.controller.test.js (20 tests)
PASS  tests/unit/settings.test.js (16 tests)
PASS  tests/unit/buildassist.test.js (12 tests)
PASS  tests/unit/user.test.js (15 tests)
PASS  tests/integration/api.integration.test.js (17 tests)
PASS  tests/security/security.test.js (19 tests)
PASS  tests/performance/performance.test.js (14 tests)

Test Suites: 17 passed, 17 total
Tests:       ~260 passed, ~260 total
```

### Frontend Test Execution

After running `flutter test`, expect:

```
00:03 +85: All tests passed!
```

### Coverage Reports

Coverage reports are generated in:
- **Backend:** `procurax_backend/coverage/` (lcov, clover, json-summary, text)
- **Frontend:** `procurax_frontend/coverage/` (lcov)

---

## Test Design Principles

1. **Arrange-Act-Assert (AAA)** — All tests follow the AAA pattern
2. **Single Responsibility** — Each test verifies one behaviour
3. **Independence** — Tests don't depend on execution order
4. **Descriptive Naming** — Test names describe expected behaviour
5. **Edge Cases** — Null, empty, invalid, and boundary inputs tested
6. **Mock Isolation** — External dependencies (DB, API) are mocked
7. **Performance Budgets** — Non-functional tests enforce timing constraints

---

*Last updated: $(date +%Y-%m-%d)*
*Testing framework: Jest 30.3 (Backend) | flutter_test (Frontend)*
