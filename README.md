<div align="center">

<br/>

<img src="procurax_frontend/assets/procurax_app_logo.png" alt="ProcuraX Logo" width="130"/>

<br/>

# ProcuraX

### Intelligent Procurement & Construction Management System

> _Transforming how the International Construction Consortium (ICC) plans, tracks, and delivers construction projects — from paper to platform._

<br/>

<!-- Core Platform Badges -->

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Node.js](https://img.shields.io/badge/Node.js-22.x-339933?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org)
[![Express](https://img.shields.io/badge/Express-5.x-000000?style=for-the-badge&logo=express&logoColor=white)](https://expressjs.com)

<!-- Data & Infrastructure Badges -->

[![MongoDB](https://img.shields.io/badge/MongoDB-Atlas%208.x-47A248?style=for-the-badge&logo=mongodb&logoColor=white)](https://www.mongodb.com/atlas)
[![Redis](https://img.shields.io/badge/Redis-7.x-DC382D?style=for-the-badge&logo=redis&logoColor=white)](https://redis.io)
[![Firebase](https://img.shields.io/badge/Firebase-FCM%20+%20Auth-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Cloudinary](https://img.shields.io/badge/Cloudinary-CDN%20Media-3448C5?style=for-the-badge&logo=cloudinary&logoColor=white)](https://cloudinary.com)

<!-- Security & Quality Badges -->

[![JWT](https://img.shields.io/badge/JWT-Auth-000000?style=for-the-badge&logo=jsonwebtokens&logoColor=white)](https://jwt.io)
[![Jest](https://img.shields.io/badge/Jest-30.3%20Tests-C21325?style=for-the-badge&logo=jest&logoColor=white)](https://jestjs.io)
[![Tests](https://img.shields.io/badge/Tests-~345%20Passing-brightgreen?style=for-the-badge&logo=checkmarx&logoColor=white)](#11-testing-strategy)

<!-- Platform & Meta Badges -->

[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=for-the-badge&logo=android&logoColor=white)](https://flutter.dev/multi-platform)
[![Railway](https://img.shields.io/badge/Deployed-Railway-0B0D0E?style=for-the-badge&logo=railway&logoColor=white)](https://railway.app)
[![License](https://img.shields.io/badge/License-ISC-blue?style=for-the-badge)](#)
[![IIT](https://img.shields.io/badge/IIT%20%7C%20Westminster-5COSC021C-8B0000?style=for-the-badge)](https://www.iit.ac.lk)
[![Version](https://img.shields.io/badge/Version-1.0.0-blueviolet?style=for-the-badge)](#)

</div>

---

## Table of Contents

1. [Overview](#1-overview)
2. [System Architecture](#2-system-architecture)
3. [Tech Stack — Deep Dive](#3-tech-stack--deep-dive)
4. [Core Modules](#4-core-modules)
5. [Authentication & Security](#5-authentication--security)
6. [API Design & Middleware](#6-api-design--middleware)
7. [Database Design](#7-database-design)
8. [Notification System](#8-notification-system)
9. [Frontend Architecture](#9-frontend-architecture)
10. [BuildAssist AI Chatbot](#10-buildassist-ai-chatbot)
11. [Testing Strategy](#11-testing-strategy)
12. [Deployment](#12-deployment)
13. [Getting Started](#13-getting-started)
14. [User Roles & Permissions](#14-user-roles--permissions)
15. [Project Structure](#15-project-structure)
16. [Environment Variables](#16-environment-variables)
17. [Academic & Team Info](#17-academic--team-info)

---

## 1. Overview

**ProcuraX** is a production-grade, full-stack mobile platform built for the **International Construction Consortium (ICC)**. It replaces a fragmented ecosystem of Excel spreadsheets, WhatsApp groups, paper-based approvals, and siloed email threads with a single, role-aware digital platform accessible from Android and iOS devices.

### The Problem

```
Before ProcuraX
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 📊 Excel files with no version control or audit trail
 📱 WhatsApp groups for procurement decisions
 📧 Email chains for meeting coordination
 📄 Paper-based document approvals
 ⏰ Missed deadlines — no automated reminders
 🔒 No role-based access control
 👁️ Zero real-time project visibility
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### The Solution

| Capability                       | How ProcuraX Delivers It                                                              |
| -------------------------------- | ------------------------------------------------------------------------------------- |
| **Real-time project visibility** | Live dashboard with KPI cards and status feeds powered by MongoDB aggregation         |
| **Procurement automation**       | Digital schedules with CSV import, delivery tracking, and automated delay alerts      |
| **Task management**              | Assignable tasks with priority, due dates, and progress tracking across projects      |
| **Smart meeting calendar**       | Conflict detection, Google Calendar sync, GPS-based location reminders                |
| **Centralised communication**    | Real-time chat, file sharing, presence indicators, and broadcast alerts via Firestore |
| **Intelligent reminders**        | Multi-channel push + email notifications via Bull queues and Firebase FCM             |
| **Secure access**                | JWT + RBAC with admin approval workflow for account provisioning                      |
| **AI assistance**                | BuildAssist chatbot for construction-domain guidance with voice input                 |
| **Document management**          | Cloud-hosted uploads via Cloudinary CDN with in-app preview                           |

---

## 2. System Architecture

### High-Level Platform Architecture

```mermaid
graph TB
    subgraph Mobile["📱 Flutter Mobile Client (Android / iOS)"]
        UI_L[UI Layer — Material 3 + Custom Widgets]
        STATE[State Layer — Provider + ChangeNotifier]
        SVC_L[Service Layer — HTTP + Firebase Clients]
        LOCAL[Local Cache — SharedPreferences]
    end

    subgraph API["⚙️ Node.js 22 / Express 5 REST API"]
        GW[API Gateway]
        PIPE[Middleware Pipeline]
        V1[Versioned Routes /api/v1/]
        CTRL[Controllers — Thin HTTP Handlers]
        BIZ[Business Logic — Service Layer]
        DAL[Data Access Layer — Mongoose ODM]
    end

    subgraph Persistence["🗄️ Data Persistence"]
        MONGO[(MongoDB Atlas\nReplica Set — Primary Store)]
        REDIS[(Redis 7.x\nCache + Job Queues)]
        CLOUD[Cloudinary CDN\nImages + Documents]
    end

    subgraph Realtime["⚡ Real-Time & Messaging"]
        FS[Cloud Firestore\nChat + Presence Sync]
        FCM[Firebase Cloud Messaging\nPush Notifications]
    end

    subgraph External["🌐 External Integrations"]
        GAUTH[Google OAuth 2.0\nSSO Login]
        GCAL[Google Calendar API\nMeeting Sync]
        GMAPS[Google Maps SDK\nLocation + Geofencing]
        EMAIL[Nodemailer + Resend\nTransactional Email]
        AI_SVC[BuildAssist AI Engine\nLLM Integration]
    end

    Mobile -->|HTTPS REST + JWT| API
    Mobile <-->|Real-time streams| FS
    Mobile <--|Push messages| FCM

    API --> DAL --> MONGO
    API --> REDIS
    API --> CLOUD
    API --> FCM
    API --> GAUTH
    API --> GCAL
    API --> EMAIL
    API --> AI_SVC

    Mobile --> GMAPS
```

### Three-Tier Layered Architecture

The backend follows strict **Separation of Concerns** across three tiers — no layer reaches beyond its boundary:

```mermaid
graph TB
    subgraph Tier1["Tier 1 — Presentation Layer"]
        direction LR
        ROUTES[Routes\nHTTP endpoint definitions]
        CTRL2[Controllers\nparse req → call service → send res]
        VALID[Joi Middleware\nvalidate body / params / query]
    end

    subgraph Tier2["Tier 2 — Business Logic Layer"]
        direction LR
        TS[TaskService]
        NS[NoteService]
        MS[MeetingService]
        PS[ProjectService]
        NOS[NotificationService]
        CS[CacheService]
        JQ[JobQueue\nBull + Redis]
    end

    subgraph Tier3["Tier 3 — Data Access Layer"]
        direction LR
        TM[Task Model]
        NM[Note Model]
        MM[Meeting Model]
        PM[Project Model]
        UM[User Model]
        NOTM[Notification Model]
    end

    subgraph CC["Cross-Cutting Concerns — core/"]
        direction LR
        ERR[AppError\nCustom error class]
        LOG[Winston Logger\nStructured JSON logs]
        RL[Rate Limiters\nPer-route strategies]
        TRACE[Distributed Tracing\nW3C Trace Context]
        METRICS[Metrics Service\nPerformance monitoring]
        AUTH_CC[JWT Auth + RBAC\nCentralised middleware]
    end

    Tier1 --> Tier2
    Tier2 --> Tier3
    Tier3 --> MongoDB[(MongoDB Atlas)]
    CC -.->|applied across all tiers| Tier1
    CC -.-> Tier2
```

### Request Lifecycle — Sequence Diagram

```mermaid
sequenceDiagram
    actor App as 📱 Flutter App
    participant GW as API Gateway
    participant RID as Request ID Middleware
    participant RL as Rate Limiter
    participant JWT as JWT Auth
    participant VAL as Joi Validator
    participant CTRL as Controller
    participant SVC as Service
    participant CACHE as Redis Cache
    participant DB as MongoDB

    App->>GW: HTTPS POST /api/v1/tasks  +  Bearer <token>
    GW->>RID: Assign UUID correlation ID
    RID->>RL: Check rate limit (IP + endpoint)
    alt Rate limit exceeded
        RL-->>App: 429 Too Many Requests
    end
    RL->>JWT: Verify JWT signature + expiry
    alt Token invalid or expired
        JWT-->>App: 401 Unauthorized
    end
    JWT->>VAL: Validate request body against Joi schema
    alt Validation failure
        VAL-->>App: 422 Unprocessable Entity + error details
    end
    VAL->>CTRL: Attach validated data to req
    CTRL->>SVC: taskService.create(data, userId)
    SVC->>CACHE: Check Redis for cached data
    alt Cache hit
        CACHE-->>SVC: Return cached result
    else Cache miss
        SVC->>DB: db.collection.insertOne(doc)
        DB-->>SVC: Inserted document
        SVC->>CACHE: Store result (TTL 5min)
    end
    SVC-->>CTRL: { success: true, task: {...} }
    CTRL-->>App: 201 Created  +  JSON envelope
```

---

## 3. Tech Stack — Deep Dive

### Backend Technologies

| Technology                                                                                                                                | Version           | Purpose                       | Design Rationale                                                                                                                                                                              |
| ----------------------------------------------------------------------------------------------------------------------------------------- | ----------------- | ----------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ![Node.js](https://img.shields.io/badge/-Node.js-339933?logo=node.js&logoColor=white&style=flat-square) **Node.js**                       | `22.x`            | JavaScript runtime            | Non-blocking I/O event loop handles thousands of concurrent procurement API calls without thread overhead. Native ESM (`"type": "module"`) enables clean tree-shakable imports.               |
| ![Express](https://img.shields.io/badge/-Express%205-000000?logo=express&logoColor=white&style=flat-square) **Express**                   | `^5.2.1`          | HTTP framework                | Express 5 adds native async error propagation — `async` route handlers no longer require try-catch wrappers. Minimal surface area allows full control of the middleware stack.                |
| ![MongoDB](https://img.shields.io/badge/-MongoDB-47A248?logo=mongodb&logoColor=white&style=flat-square) **MongoDB Atlas**                 | `8.x`             | Primary database              | Document model maps naturally to hierarchical construction data (procurement schedules, nested task hierarchies, meeting attendees). Atlas replica sets provide HA with automatic failover.   |
| ![Mongoose](https://img.shields.io/badge/-Mongoose-880000?logo=mongoose&logoColor=white&style=flat-square) **Mongoose**                   | `^8.12.1`         | ODM layer                     | Schema validation, virtuals, compound indexes, and middleware hooks at the model level. Prevents schema drift as the team scales.                                                             |
| ![Redis](https://img.shields.io/badge/-Redis-DC382D?logo=redis&logoColor=white&style=flat-square) **Redis + ioredis**                     | `7.x / ^5.6.1`    | Cache + job queue             | Sub-millisecond reads for hot data (active dashboard, notification counts). Bull queues backed by Redis provide reliable background job processing with retry logic and dead-letter handling. |
| ![Bull](https://img.shields.io/badge/-Bull-E74C3C?style=flat-square) **Bull**                                                             | `^4.16.5`         | Background jobs               | Priority-aware job queues for notification dispatch, email sending, and scheduled procurement reminders. Failed jobs retry with exponential backoff.                                          |
| ![JWT](https://img.shields.io/badge/-JWT-000000?logo=jsonwebtokens&logoColor=white&style=flat-square) **jsonwebtoken**                    | `^9.0.3`          | Stateless auth                | Signed tokens carry `userId`, `role`, and `exp` — no server-side session storage required. Short-lived access tokens + refresh token rotation minimise exposure window.                       |
| ![bcrypt](https://img.shields.io/badge/-bcryptjs-555555?style=flat-square) **bcryptjs**                                                   | `^3.0.3`          | Password hashing              | Adaptive cost factor (12 rounds) makes brute-force and rainbow table attacks computationally infeasible.                                                                                      |
| ![Firebase](https://img.shields.io/badge/-Firebase%20Admin-FFCA28?logo=firebase&logoColor=black&style=flat-square) **Firebase Admin SDK** | `^13.6.0`         | Push notifications            | Reliable FCM delivery to both Android and iOS from a single SDK call. Supports data + notification payloads for background wake and foreground display.                                       |
| ![Cloudinary](https://img.shields.io/badge/-Cloudinary-3448C5?logo=cloudinary&logoColor=white&style=flat-square) **Cloudinary**           | `^2.9.0`          | Media/document CDN            | Secure signed upload URLs, automatic image optimisation, CDN-edge delivery, and format transcoding. Eliminates need for self-hosted S3-compatible storage.                                    |
| ![Joi](https://img.shields.io/badge/-Joi-E34F26?style=flat-square) **Joi**                                                                | `^18.0.2`         | Input validation              | Declarative schema-based validation at all system boundaries. Centralised schemas in `core/validation/schemas.js` are reused across routes.                                                   |
| ![Winston](https://img.shields.io/badge/-Winston-231F20?style=flat-square) **Winston**                                                    | `^3.19.0`         | Structured logging            | JSON-formatted logs with request correlation IDs, severity levels, and context metadata. Production logs ship to file + console transports.                                                   |
| ![Nodemailer](https://img.shields.io/badge/-Nodemailer-22B573?style=flat-square) **Nodemailer + Resend**                                  | `^8.0.1 / ^6.9.4` | Transactional email           | Dual-provider strategy: Nodemailer for SMTP delivery, Resend API as fallback. Ensures email deliverability even during SMTP outages.                                                          |
| ![Google](https://img.shields.io/badge/-Google%20APIs-4285F4?logo=google&logoColor=white&style=flat-square) **Google APIs**               | `^169.0.0`        | OAuth + Calendar              | Server-side Google OAuth token verification and Calendar event creation for smart meeting sync.                                                                                               |
| ![Multer](https://img.shields.io/badge/-Multer-FF6C37?style=flat-square) **Multer**                                                       | `^2.0.2`          | File upload handling          | Streaming multipart/form-data parsing with type validation and file size limits before Cloudinary upload.                                                                                     |
| ![express-rate-limit](https://img.shields.io/badge/-express--rate--limit-orange?style=flat-square) **express-rate-limit**                 | `^8.3.1`          | DDoS / brute-force protection | Tiered limiters per route category: stricter on auth endpoints, relaxed on read-only API.                                                                                                     |

### Frontend Technologies

| Technology                                                                                                                                      | Version            | Purpose                     | Design Rationale                                                                                                                                                                  |
| ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ![Flutter](https://img.shields.io/badge/-Flutter-02569B?logo=flutter&logoColor=white&style=flat-square) **Flutter**                             | `3.x`              | Cross-platform UI framework | Single Dart codebase compiles to native ARM for Android and iOS. Pixel-perfect custom widgets match ICC's branding without platform limitations.                                  |
| ![Dart](https://img.shields.io/badge/-Dart-0175C2?logo=dart&logoColor=white&style=flat-square) **Dart**                                         | `^3.9.0`           | Language                    | Sound null safety eliminates NPEs at compile time. AOT compilation produces fast startup and smooth 60fps UI.                                                                     |
| ![Provider](https://img.shields.io/badge/-Provider-7C3AED?style=flat-square) **Provider**                                                       | `^6.1.2`           | State management            | `ChangeNotifier` + `Consumer` pattern provides reactive rebuilds without Bloc boilerplate overhead. Sufficient for a team of this size.                                           |
| ![Firebase Auth](https://img.shields.io/badge/-Firebase%20Auth-FFCA28?logo=firebase&logoColor=black&style=flat-square) **Firebase Auth**        | `^5.0.0`           | Client-side auth            | Handles Google Sign-In token flow, ID token refresh, and integration with FCM device registration.                                                                                |
| ![Firestore](https://img.shields.io/badge/-Firestore-FFCA28?logo=firebase&logoColor=black&style=flat-square) **Cloud Firestore**                | `^5.0.0`           | Real-time chat data         | `StreamBuilder` on Firestore collections delivers zero-latency message delivery without polling. Offline persistence ensures the chat works in low-connectivity field conditions. |
| ![Firebase Messaging](https://img.shields.io/badge/-FCM%20Client-FFCA28?logo=firebase&logoColor=black&style=flat-square) **Firebase Messaging** | `^15.2.4`          | Push notification reception | Background isolate handler (`@pragma('vm:entry-point')`) processes FCM messages even when app is terminated.                                                                      |
| ![Google Maps](https://img.shields.io/badge/-Google%20Maps-4285F4?logo=googlemaps&logoColor=white&style=flat-square) **Google Maps Flutter**    | `^2.12.1`          | Mapping + geofencing        | Native Maps SDK wrapper for site visualisation and location-aware meeting reminders.                                                                                              |
| ![Geolocator](https://img.shields.io/badge/-Geolocator-00BCD4?style=flat-square) **Geolocator + Geocoding**                                     | `^13.0.4 / ^3.0.0` | GPS services                | High-accuracy GPS position for geofenced meeting proximity alerts. Geocoding resolves human-readable addresses to coordinates.                                                    |
| ![table_calendar](https://img.shields.io/badge/-table__calendar-1976D2?style=flat-square) **table_calendar**                                    | `^3.1.2`           | Calendar widget             | Rich calendar rendering with custom event markers, selectable days, and range selection. Powers the smart meeting scheduler.                                                      |
| ![speech_to_text](https://img.shields.io/badge/-speech__to__text-E91E63?style=flat-square) **speech_to_text**                                   | `^7.3.0`           | Voice input                 | Platform-native speech recognition for voice queries to BuildAssist AI.                                                                                                           |
| **shared_preferences**                                                                                                                          | `^2.2.3`           | Local storage               | Persists auth tokens, user preferences, and theme settings across app launches.                                                                                                   |
| **file_picker + image_picker**                                                                                                                  | `^8.1.7 / ^1.0.4`  | File handling               | Document selection and camera/gallery image capture for procurement and document uploads.                                                                                         |
| **flutter_local_notifications**                                                                                                                 | `^18.0.1`          | On-device alerts            | Schedules and displays meeting reminders and task alerts even when the app is backgrounded.                                                                                       |
| **Google Fonts**                                                                                                                                | `^6.0.0`           | Typography                  | Poppins + Inter for consistent, modern typeface that matches ICC's brand identity.                                                                                                |
| **lucide_icons**                                                                                                                                | `^0.257.0`         | Icon system                 | Consistent, minimal icon set across all screens.                                                                                                                                  |

### Infrastructure & DevOps

| Technology                                                                                                          | Role             | Details                                                                                 |
| ------------------------------------------------------------------------------------------------------------------- | ---------------- | --------------------------------------------------------------------------------------- |
| ![Railway](https://img.shields.io/badge/-Railway-0B0D0E?logo=railway&logoColor=white&style=flat-square) **Railway** | Backend hosting  | Zero-config cloud deployment with auto-SSL, custom domains, and env variable management |
| **MongoDB Atlas**                                                                                                   | Managed database | M0→M10 cluster scaling, automated backups, replica set for HA                           |
| **Nixpacks**                                                                                                        | Build system     | Detects Node.js project, installs deps, sets start command — no Dockerfile needed       |
| **GitHub Actions**                                                                                                  | CI pipeline      | Lint → test → build on every pull request                                               |
| **Cloudinary CDN**                                                                                                  | Media delivery   | 150+ CDN PoPs for low-latency asset delivery globally                                   |

---

## 4. Core Modules

### Module Overview

```mermaid
mindmap
  root((ProcuraX))
    🔐 Auth & Access
      Email + Password Login
      Google OAuth SSO
      Admin Approval Workflow
      JWT + Refresh Tokens
      RBAC — 6 Role Levels
    📊 Dashboard
      Project KPI Cards
      Procurement Status
      Recent Activity Feed
      Notification Badge
    📦 Procurement
      Schedule Management
      Material Delivery Tracking
      CSV Bulk Import
      Automated Delay Alerts
      Supplier Details
    ✅ Tasks
      Task Assignment
      Priority Levels
      Due Date Tracking
      Status Workflow
      Per-Project Filtering
    📝 Notes
      Site Notes
      Photo Attachments
      Tag Organisation
      Full-Text Search
      Soft Delete
    📅 Smart Calendar
      Meeting Scheduler
      Conflict Detection
      Google Calendar Sync
      Attendee Invites
      GPS Reminders
    🔔 Notifications
      FCM Push
      Email — Nodemailer/Resend
      Bull Job Queue
      Priority Levels
      Read/Unread State
    📁 Documents
      Cloudinary Upload
      CDN Download
      In-App Preview
      Metadata Tagging
    💬 Communication
      Real-Time Chat
      File Sharing
      Typing Indicators
      Online Presence
      Broadcast Alerts
      Voice/Video Calls
    🤖 BuildAssist AI
      NLP Chatbot
      Voice Input
      Construction Knowledge Base
      Conversation History
    ⚙️ Admin Panel
      User Approval
      Role Management
      Project Creation
      System Stats
    🔧 Settings
      Profile Management
      Theme — Dark/Light
      Notification Prefs
      Password Change
```

### 4.1 Authentication Module

```mermaid
flowchart TD
    A([User Opens App]) --> B{Token in\nSharedPreferences?}
    B -- Yes --> C[Validate JWT Expiry]
    C -- Valid --> DASH[🏠 Dashboard]
    C -- Expired --> REFRESH[Attempt Token Refresh]
    REFRESH -- Success --> DASH
    REFRESH -- Fail --> LOGIN

    B -- No --> START[Get Started Page]
    START --> AUTH_CHOICE{Auth Method}
    AUTH_CHOICE -- Email/Password --> LOGIN[Login Page]
    AUTH_CHOICE -- Google SSO --> GOOGLE[Google OAuth Flow\nFirebase Auth]

    LOGIN -- Submit --> API_LOGIN[POST /auth/login\nValidate credentials]
    GOOGLE --> API_GOOGLE[POST /auth/google\nVerify ID token]

    API_LOGIN --> BCRYPT{bcrypt.compare\npassword}
    BCRYPT -- No Match --> ERR401[401 Unauthorized]
    BCRYPT -- Match --> CHECK_STATUS

    API_GOOGLE --> CHECK_STATUS{Account Status}

    CHECK_STATUS -- pending --> PENDING[⏳ Waiting for\nAdmin Approval]
    CHECK_STATUS -- rejected --> DENIED[❌ Access Denied]
    CHECK_STATUS -- active --> TOKENS[Issue JWT\n+ Refresh Token]

    TOKENS --> STORE[Store in\nSharedPreferences]
    STORE --> DASH
```

**Key Security Properties:**

- Passwords hashed with **bcryptjs** — 12 adaptive salt rounds
- Access tokens: short-lived (15 min default), signed with `JWT_SECRET`
- Refresh tokens: longer-lived, rotated on each use
- Admin approval gate: all new accounts start as `status: "pending"` — no access until an admin explicitly activates
- Rate-limited: 20 login attempts per 15 minutes per IP, 3 registrations per hour

### 4.2 Procurement Module

The core business module — tracks every material and supplier across all ICC projects:

```mermaid
flowchart LR
    A[Create Procurement\nSchedule] --> B[Add Line Items\nitem, qty, supplier]
    B --> C[Set Expected\nDelivery Dates]
    C --> D[Link to\nProject]
    D --> E{Delivery\nStatus}
    E -- On Track --> F[✅ Mark Delivered]
    E -- Delayed --> G[🚨 Automated Alert]
    G --> H[Bull Queue:\nnotification.send job]
    H --> I[FCM Push +\nEmail to PM]
    F --> J[Update Dashboard\nKPI Card]
    E -- Pending --> K[Daily Reminder\nScheduler]
    K --> H
```

- Full CRUD on procurement schedules
- **CSV bulk import** — `csv-parse` library handles bulk material uploads
- Delivery status tracking: `Pending` → `In Transit` → `Delivered` / `Delayed`
- Automated delay notifications via the scheduler
- Finance department read access for budget review

### 4.3 Tasks Module

```mermaid
stateDiagram-v2
    [*] --> Open : Task Created
    Open --> InProgress : Assignee starts work
    InProgress --> UnderReview : Submitted for review
    UnderReview --> InProgress : Reviewer requests changes
    UnderReview --> Completed : Approved
    Completed --> [*]
    Open --> Cancelled : Cancelled by PM
    InProgress --> Cancelled : Cancelled by PM
```

- Assignable to any user by a Project Manager or above
- Priority levels: `Low` | `Medium` | `High` | `Critical`
- Due date tracking with automated overdue detection
- Filter by project, assignee, priority, and status
- `TaskService` provides CRUD + aggregation statistics (completion rate, overdue count)

### 4.4 Smart Calendar & Meetings

```mermaid
sequenceDiagram
    participant PM as Project Manager
    participant App as Flutter App
    participant API as Backend API
    participant Conflicts as Conflict Detector
    participant GCal as Google Calendar API
    participant FCM2 as Firebase FCM
    participant Geo as Geofencing Service

    PM->>App: Create meeting (title, time, location, attendees)
    App->>API: POST /api/v1/meetings
    API->>Conflicts: Check attendee calendars for overlap
    alt Conflict found
        Conflicts-->>App: ⚠️ Conflict warning with details
        PM->>App: Adjust time or confirm override
    end
    App->>API: Confirm create
    API->>GCal: Create Google Calendar event
    GCal-->>API: Event ID
    API->>FCM2: Send invite push to all attendees
    FCM2-->>App: 🔔 Meeting invite notification

    Note over App,Geo: 1 hour before meeting
    Geo->>App: GPS geofence check — near venue?
    App->>App: 📍 Location-aware reminder triggered
```

### 4.5 Communication Hub

```mermaid
graph TB
    subgraph CommHub["💬 Communication Hub"]
        DM[Direct Messages]
        GRP[Group Channels]
        FA[File Attachments]
        BCAST[Broadcast Alerts]
        PRES[Online Presence]
        TYPE[Typing Indicators]
        CALLS[Voice / Video Calls]
    end

    subgraph Tech["Underlying Technology"]
        FS2[Cloud Firestore\nReal-time streams]
        CDN2[Cloudinary\nFile storage]
        FCM3[Firebase FCM\nPush for offline users]
    end

    DM --> FS2
    GRP --> FS2
    PRES --> FS2
    TYPE --> FS2
    FA --> CDN2
    BCAST --> FCM3
    CALLS --> API3[Backend Call\nManagement Routes]
```

---

## 5. Authentication & Security

### Security Architecture

```mermaid
graph TB
    subgraph Input["Input Security"]
        A1[Joi Schema Validation\nall endpoints]
        A2[Multer File Type\n+ Size Validation]
        A3[MongoDB via Mongoose ODM\nParameterised queries]
    end

    subgraph Network["Network Security"]
        B1[CORS — Whitelist\norigins only]
        B2[HTTPS / TLS\nall traffic]
        B3[Rate Limiting\nPer route strategy]
        B4[Request ID + Tracing\nW3C Trace Context]
    end

    subgraph AuthZ["Authentication + Authorisation"]
        C1[bcrypt 12 rounds\npassword hashing]
        C2[JWT Access Tokens\nshort-lived, signed]
        C3[Refresh Token Rotation\ninvalidate on use]
        C4[RBAC Middleware\nrequireRole checks]
        C5[Admin Approval Gate\npending by default]
    end

    subgraph Observability["Observability"]
        D1[Winston Structured Logs\nJSON + correlation ID]
        D2[Distributed Tracing\nW3C headers]
        D3[Metrics Service\nperformance tracking]
        D4[Error Envelope\nconsistent format]
    end
```

### Rate Limiting Strategy

| Endpoint Category            | Limit        | Window          |
| ---------------------------- | ------------ | --------------- |
| `POST /auth/login`           | 20 requests  | 15 minutes / IP |
| `POST /auth/register`        | 3 requests   | 1 hour / IP     |
| `POST /auth/forgot-password` | 5 requests   | 1 hour / IP     |
| `POST /media/upload`         | 10 requests  | 5 minutes / IP  |
| General API `/api/*`         | 100 requests | 15 minutes / IP |

### Consistent Error Envelope

Every error response follows the same structure, enabling reliable client-side handling:

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "title is required",
    "statusCode": 422,
    "requestId": "550e8400-e29b-41d4-a716-446655440000",
    "timestamp": "2026-04-20T10:30:00.000Z"
  }
}
```

---

## 6. API Design & Middleware

### API Route Map

```mermaid
graph LR
    ROOT[/] --> HEALTH[/health\nGET — liveness probe]
    ROOT --> V1[/api/v1/]
    ROOT --> LEGACY[/api/ — legacy compat]
    ROOT --> ADMIN[/admin-api/]

    V1 --> T[/tasks\nGET POST PUT DELETE]
    V1 --> N[/notes\nGET POST PUT DELETE]
    V1 --> M[/meetings\nGET POST PUT DELETE]
    V1 --> NOTIF[/notifications\nGET PATCH DELETE]
    V1 --> PROJ[/projects\nGET POST PUT DELETE]

    LEGACY --> AUTH_R[/auth\nlogin register refresh logout]
    LEGACY --> PROC_R[/procurement\nfull CRUD + CSV]
    LEGACY --> COMM[/communication\nchat calls files presence alerts]
    LEGACY --> DOCS[/documents\nupload download list]
    LEGACY --> CHATBOT[/buildassist\nquery history]
    LEGACY --> USR[/users\nprofile settings]

    ADMIN --> ADMIN_AUTH[/auth — admin login]
    ADMIN --> ADMIN_USR[/users — approve/reject]
    ADMIN --> ADMIN_MGR[/managers — assignment]
    ADMIN --> ADMIN_PROJ[/projects — creation]
    ADMIN --> ADMIN_STATS[/stats — system metrics]
```

### Middleware Pipeline

Every request passes through the following chain in order:

```mermaid
flowchart TD
    REQ([📥 Incoming Request]) --> M1

    M1["1️⃣ requestIdMiddleware\nAssign UUID v4 correlation ID\nAttach to req.id + response header"] --> M2

    M2["2️⃣ tracingMiddleware\nW3C Trace Context headers\ntraceparent + tracestate"] --> M3

    M3["3️⃣ httpLogger\nWinston structured request log\nmethod + path + status + ms"] --> M4

    M4["4️⃣ CORS Handler\nOrigin whitelist check\nPreflight OPTIONS handling"] --> M5

    M5["5️⃣ Rate Limiter\nexpress-rate-limit\nPer-IP sliding window"] --> M6

    M6["6️⃣ JSON Body Parser\nexpress.json() + express.urlencoded()"] --> M7

    M7["7️⃣ JWT Auth Middleware\njwt.verify() + decode payload\nAttach req.user = { id, role }"] --> M8

    M8["8️⃣ RBAC Guard\nrequireRole(['admin','manager'])\nreject if insufficient role"] --> M9

    M9["9️⃣ Joi Validation Middleware\nvalidateBody / validateQuery / validateParams\nthrow 422 on schema mismatch"] --> M10

    M10["🔟 Controller\nThin handler: parse → service call → respond"] --> M11

    M11["⚠️ Global Error Handler\nAppError → structured JSON\nStack trace in development only"] --> RES

    RES([📤 JSON Response])
```

---

## 7. Database Design

### Entity Relationship Diagram

```mermaid
erDiagram
    USER {
        ObjectId _id PK
        string name
        string email
        string passwordHash
        string role
        string status
        string profileImage
        ObjectId projectId FK
        date createdAt
        date updatedAt
    }

    PROJECT {
        ObjectId _id PK
        string name
        string description
        string status
        ObjectId managerId FK
        date startDate
        date endDate
        date createdAt
    }

    TASK {
        ObjectId _id PK
        string title
        string description
        string status
        string priority
        ObjectId assigneeId FK
        ObjectId projectId FK
        date dueDate
        date completedAt
        date createdAt
    }

    NOTE {
        ObjectId _id PK
        string title
        string content
        string[] tags
        string[] attachments
        ObjectId authorId FK
        ObjectId projectId FK
        boolean isDeleted
        date createdAt
    }

    MEETING {
        ObjectId _id PK
        string title
        string description
        string location
        float[] coordinates
        date startTime
        date endTime
        ObjectId[] attendees FK
        ObjectId organiserId FK
        string googleEventId
        boolean hasConflict
        date createdAt
    }

    PROCUREMENT {
        ObjectId _id PK
        string itemName
        string supplier
        string status
        number quantity
        string unit
        number unitCost
        date expectedDelivery
        date actualDelivery
        ObjectId projectId FK
        ObjectId createdBy FK
        date createdAt
    }

    NOTIFICATION {
        ObjectId _id PK
        string title
        string message
        string type
        string priority
        boolean isRead
        ObjectId userId FK
        ObjectId taskId FK
        ObjectId projectId FK
        object metadata
        date createdAt
    }

    USER ||--o{ TASK : "assigned to"
    USER ||--o{ NOTE : "authored by"
    USER ||--o{ NOTIFICATION : "receives"
    USER }o--o{ MEETING : "attends"
    USER ||--o{ PROCUREMENT : "created by"
    PROJECT ||--o{ TASK : "contains"
    PROJECT ||--o{ NOTE : "scoped to"
    PROJECT ||--o{ MEETING : "related to"
    PROJECT ||--o{ PROCUREMENT : "tracks"
    USER }|--|| PROJECT : "belongs to"
```

### Index Strategy

Compound indexes ensure sub-5ms query performance on high-traffic collections:

| Collection      | Index Fields                               | Type     | Query Served             |
| --------------- | ------------------------------------------ | -------- | ------------------------ |
| `users`         | `{ email: 1 }`                             | Unique   | Login lookup             |
| `tasks`         | `{ assigneeId: 1, status: 1 }`             | Compound | User's task list         |
| `tasks`         | `{ projectId: 1, dueDate: 1 }`             | Compound | Project timeline         |
| `tasks`         | `{ projectId: 1, status: 1, priority: 1 }` | Compound | Filtered board views     |
| `notifications` | `{ userId: 1, isRead: 1 }`                 | Compound | Unread count badge       |
| `notifications` | `{ userId: 1, createdAt: -1 }`             | Compound | Chronological feed       |
| `meetings`      | `{ startTime: 1, attendees: 1 }`           | Compound | Conflict detection       |
| `procurement`   | `{ projectId: 1, status: 1 }`              | Compound | Project procurement view |
| `notes`         | `{ projectId: 1, isDeleted: 1 }`           | Compound | Active notes per project |

---

## 8. Notification System

### Notification Architecture

```mermaid
flowchart TB
    subgraph Triggers["⚡ Event Sources"]
        T1[Task Assigned]
        T2[Task Overdue]
        T3[Procurement Delayed]
        T4[Meeting Invite]
        T5[1hr Pre-Meeting]
        T6[Admin Approval]
        T7[System Alert]
    end

    subgraph Scheduler["⏰ Cron Scheduler — scheduler.js"]
        S1[Every minute\nCheck overdue tasks]
        S2[Daily 08:00\nProcurement reminders]
        S3[1hr before meeting\nPre-meeting alert]
        S4[Daily 09:00\nDigest email]
    end

    subgraph Queue["🔄 Bull Job Queue — Redis-backed"]
        Q1[notification.send\nPriority: critical/high/medium/low]
        Q2[email.dispatch\nRetry: 3 attempts, exp backoff]
        Q3[push.fcm\nBatch delivery]
    end

    subgraph Workers["⚙️ Job Workers"]
        W1[NotificationService.create\nPersist to MongoDB]
        W2[Firebase Admin SDK\nFCM dispatch]
        W3[Nodemailer\nSMTP delivery]
        W4[Resend API\nFallback email]
    end

    subgraph Delivery["📬 Delivery Channels"]
        D1[(MongoDB\nPersisted notifications)]
        D2[Firebase FCM\nAndroid + iOS push]
        D3[Email Inbox\nHTML template]
        D4[In-App Badge\nNotification centre]
    end

    Triggers --> Q1
    Scheduler --> Q1
    Scheduler --> Q2

    Q1 --> W1
    Q1 --> W2
    Q2 --> W3
    Q2 --> W4
    Q3 --> W2

    W1 --> D1
    W2 --> D2
    W3 --> D3
    W4 --> D3
    D1 --> D4
```

### Notification Data Model

```
type:     projects | tasks | procurement | meetings | general
priority: critical | high  | medium      | low

Supported Operations:
  GET    /api/notifications        — paginated list, filterable
  GET    /api/notifications/:id    — single notification
  PATCH  /api/notifications/:id    — mark as read
  PATCH  /api/notifications/bulk   — bulk mark read
  DELETE /api/notifications/:id    — single delete
  DELETE /api/notifications/bulk   — bulk delete
  GET    /api/notifications/stats  — counts by type + priority
```

---

## 9. Frontend Architecture

### App Initialisation Sequence

```mermaid
sequenceDiagram
    participant OS as Device OS
    participant Main as main.dart
    participant FB as FirebaseService
    participant FCM2 as PushNotificationService
    participant GEO as MeetingNotificationService
    participant API4 as ApiService
    participant APP as MyApp Widget

    OS->>Main: Launch application
    Main->>FB: FirebaseService.initialize()
    FB-->>Main: Firebase ready
    Main->>Main: Register FCM background handler\n@pragma('vm:entry-point')
    Main->>FCM2: PushNotificationService.initialize()
    FCM2-->>Main: FCM + local notifications ready
    Main->>GEO: MeetingNotificationService.initialize()
    GEO-->>Main: Geofencing ready
    Main->>API4: ApiService.initialize()
    API4-->>Main: Base URL + token loaded
    Main->>APP: runApp(MyApp)
    APP->>APP: MultiProvider tree mounted\nThemeNotifier + AlertProvider + BuildAssistChatProvider
    APP->>APP: Check ApiService.hasToken
    APP->>APP: Route to Dashboard or GetStarted
```

### Navigation Map

```mermaid
flowchart TD
    SPLASH[Splash / Boot] --> AUTH_GATE{AuthGate\nhas token?}
    AUTH_GATE -- No --> GET_STARTED[Get Started Page]
    GET_STARTED --> LOGIN_P[Login Page]
    GET_STARTED --> SIGNUP[Create Account Page]
    LOGIN_P --> FORGOT[Forgot Password]
    AUTH_GATE -- Yes --> DASH2[🏠 Dashboard Page]

    DASH2 --> PROC_P[📦 Procurement\nSchedule Page]
    DASH2 --> TASK_P[✅ Tasks Page]
    DASH2 --> NOTE_P[📝 Notes Page]
    DASH2 --> CAL_P[📅 Meetings / Calendar Page]
    DASH2 --> COMM_P[💬 Communication Hub]
    DASH2 --> DOC_P[📁 Documents Page]
    DASH2 --> NOTIF_P[🔔 Notifications Page]
    DASH2 --> BUILD_P[🤖 BuildAssist AI Page]
    DASH2 --> SETTINGS_P[⚙️ Settings Page]
```

### Provider State Architecture

```mermaid
graph LR
    subgraph Providers["ChangeNotifier Providers"]
        TN2[ThemeNotifier\ndark / light mode]
        AP2[AlertProvider\nunread notification count]
        BAP2[BuildAssistChatProvider\nchat history state]
    end

    subgraph Services2["Service Layer"]
        API_S[ApiService\nHTTP client + token mgmt]
        AUTH_S[AuthService\nlogin / register / refresh]
        TASK_S[TasksService]
        NOTE_S[NotesService]
        PROC_S2[ProcurementService]
        MEET_S[MeetingsService]
        FS_SVC[FirebaseService\nFirestore streams]
        PUSH_S[PushNotificationService]
    end

    subgraph UI3["Widget Tree"]
        PAGES[Feature Pages]
        WIDGETS[Reusable Widgets]
    end

    UI3 -->|Consumer / context.watch| Providers
    Providers -->|async calls| Services2
    Services2 -->|HTTP| Backend[(REST API)]
    Services2 -->|streams| Firestore[(Firestore)]
```

### Design System

The app uses a consistent design system defined in `lib/theme/app_theme.dart`:

```
Color Palette:     ICC brand primary + Material 3 seed colours
Typography:        Google Fonts — Poppins (headings) + Inter (body)
Icons:             lucide_icons — 257+ minimal SVG icons
Theme Modes:       Full light + dark mode via ThemeNotifier
Border Radius:     12px cards, 8px inputs, 24px FABs
Spacing:           8px grid system
```

---

## 10. BuildAssist AI Chatbot

BuildAssist is an embedded, construction-domain AI assistant providing real-time guidance:

```mermaid
flowchart LR
    INPUT([👤 User Input]) --> CHOICE{Input Method}
    CHOICE -- Keyboard --> TEXT[Text Entry]
    CHOICE -- Voice --> STT2[speech_to_text\nPlatform speech API]
    STT2 --> TEXT
    TEXT --> PROVIDER2[BuildAssistChatProvider\nManage conversation history]
    PROVIDER2 --> API_CALL[POST /buildassist/query\n{ message, history }]
    API_CALL --> BE_SVC[BuildAssist Backend Service]
    BE_SVC --> LLM[LLM Integration\nConstruction knowledge base]
    LLM --> RESP[AI Response text]
    RESP --> PROVIDER2
    PROVIDER2 --> UI4[Chat Bubble UI\nMarkdown rendering]
    UI4 --> USER([📱 User sees response])
```

**Capabilities:**

- Construction-domain knowledge base
- Context-aware multi-turn conversations (history passed with each request)
- Voice-to-text input via platform speech recognition
- Guided procurement workflow suggestions
- Material specification lookups
- Project planning guidance

---

## 11. Testing Strategy

### Test Pyramid

```mermaid
graph TB
    E2E2["🖱️ Manual / E2E\nExploratory testing on device"]
    INT2["🔗 Integration Tests  ~17\nAPI endpoint flows, DB operations"]
    SEC["🔒 Security Tests  ~19\nJWT bypass, injection, rate limit evasion"]
    PERF["⚡ Performance Tests  ~14\nResponse time, concurrent load benchmarks"]
    UNIT_B2["🧪 Backend Unit Tests  ~210\nService layer, middleware, validation — Jest 30.3 + ESM"]
    UNIT_F2["📱 Frontend Unit Tests  ~85\nWidget tests, service mocks — flutter_test"]

    E2E2 --- INT2
    INT2 --- SEC
    SEC --- PERF
    PERF --- UNIT_B2
    UNIT_B2 --- UNIT_F2

    style E2E2 fill:#ff9800,color:#000
    style INT2 fill:#2196f3,color:#fff
    style SEC fill:#f44336,color:#fff
    style PERF fill:#9c27b0,color:#fff
    style UNIT_B2 fill:#4caf50,color:#fff
    style UNIT_F2 fill:#009688,color:#fff
```

### Test Coverage Summary

| Layer         | Count    | Tool            | Coverage Target     | Location             |
| ------------- | -------- | --------------- | ------------------- | -------------------- |
| Backend Unit  | ~210     | Jest 30.3 + ESM | ≥ 80% services      | `tests/unit/`        |
| Integration   | ~17      | Jest            | ≥ 70% routes        | `tests/integration/` |
| Security      | ~19      | Jest            | Auth + input paths  | `tests/security/`    |
| Performance   | ~14      | Jest            | Response benchmarks | `tests/performance/` |
| Frontend Unit | ~85      | flutter_test    | Widget + service    | `test/`              |
| **Total**     | **~345** |                 |                     |                      |

### What Is Tested

```mermaid
mindmap
  root(Test Coverage)
    Unit Tests
      TaskService CRUD
      NoteService pagination
      MeetingService conflict detection
      ProjectService aggregation
      NotificationService delivery
      JWT auth middleware
      Joi validation schemas
      AppError class
      Rate limiter logic
      Cache service
    Integration Tests
      POST /auth/login flow
      GET /api/v1/tasks with auth
      POST /api/v1/meetings create + conflict
      Notification pipeline end-to-end
    Security Tests
      JWT signature tampering
      Expired token rejection
      Missing token 401
      Role escalation attempts
      Injection payloads in body/params
      Rate limit enforcement
    Performance Tests
      API response time under 200ms p95
      Concurrent request handling
      MongoDB query benchmarks
      Cache hit vs miss latency
```

### Running Tests

```bash
cd procurax_backend

# Run all test suites
npm test

# Run by category
npm run test:unit
npm run test:integration
npm run test:security
npm run test:performance

# Watch mode during development
npm run test:watch

# Generate coverage report (HTML + LCOV)
npm run test:coverage

# CI mode — coverage + no cache + force exit
npm run test:ci
```

```bash
cd procurax_frontend

# Run all Flutter widget tests
flutter test

# Run with coverage
flutter test --coverage
```

---

## 12. Deployment

### CI/CD Pipeline

```mermaid
flowchart LR
    DEV[👨‍💻 Developer\ngit push] --> GH[GitHub Repository]
    GH --> CI2[GitHub Actions CI]
    CI2 --> LINT[ESLint\nCode quality check]
    LINT --> TEST2[npm run test:ci\nJest with coverage]
    TEST2 --> BUILD2{Build\nSucceeded?}
    BUILD2 -- No --> FAIL[❌ PR Blocked]
    BUILD2 -- Yes --> RAILWAY2[Railway Auto-Deploy\nnixpacks build]
    RAILWAY2 --> NIXPACKS[nixpacks detects Node.js\nnpm install + node app.js]
    NIXPACKS --> LIVE[🟢 Live API Server]
    LIVE --> ATLAS[(MongoDB Atlas)]
    LIVE --> REDIS_C[(Redis Cloud)]
    LIVE --> FCM_D[Firebase FCM]
```

### Railway Configuration

The backend auto-deploys from the `main` branch using configuration in [`railway.json`](railway.json) and [`nixpacks.toml`](nixpacks.toml):

```toml
# nixpacks.toml
[phases.build]
cmds = ["npm install"]

[start]
cmd = "npm start"
```

### Flutter Release Builds

```bash
# Android APK (sideload / testing)
flutter build apk --release

# Android App Bundle (Google Play Store)
flutter build appbundle --release

# iOS Archive (App Store — requires macOS + Xcode)
flutter build ipa --release
```

---

## 13. Getting Started

### Prerequisites

| Tool             | Minimum Version              | Install                                                             |
| ---------------- | ---------------------------- | ------------------------------------------------------------------- |
| Node.js          | `≥ 20.0.0`                   | [nodejs.org](https://nodejs.org)                                    |
| npm              | `≥ 10.0.0`                   | Bundled with Node.js                                                |
| Flutter SDK      | `≥ 3.x`                      | [flutter.dev/install](https://flutter.dev/docs/get-started/install) |
| Dart SDK         | `≥ 3.9.0`                    | Bundled with Flutter                                                |
| MongoDB          | Atlas account or local `8.x` | [mongodb.com/atlas](https://www.mongodb.com/atlas)                  |
| Redis            | `7.x`                        | [redis.io/docs/getting-started](https://redis.io)                   |
| Firebase project | FCM + Firestore enabled      | [console.firebase.google.com](https://console.firebase.google.com)  |

### Backend Setup

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_ORG/ICC_ProcuraX.git
cd ICC_ProcuraX/procurax_backend

# 2. Install dependencies
npm install

# 3. Create environment file from template
cp .env.example .env
# Edit .env — see Environment Variables section below

# 4. Start development server (hot-reload via nodemon)
npm run dev

# 5. Verify health check
curl http://localhost:5000/health
# Expected: { "status": "ok", "db": "connected", "uptime": ... }
```

### Frontend Setup

```bash
cd ICC_ProcuraX/procurax_frontend

# 1. Install Dart/Flutter dependencies
flutter pub get

# 2. Configure Firebase (google-services.json / GoogleService-Info.plist)
# Copy Firebase config files to android/app/ and ios/Runner/

# 3. Run on connected device or emulator
flutter run

# 4. List available devices
flutter devices

# 5. Run on specific device
flutter run -d <device-id>
```

---

## 14. User Roles & Permissions

### Role Hierarchy

```mermaid
graph TD
    SA2[🛡️ Super Admin\nFull system + admin panel]
    GM2[👔 General Manager\nAll modules + reporting]
    DIR2[📋 Director\nAll modules — read heavy]
    PM2[🏗️ Project Manager\nOwn projects — full CRUD]
    PE2[📐 Planning Engineer\nTasks + Notes + Calendar]
    FIN2[💰 Finance Department\nProcurement + reports]

    SA2 --> GM2
    GM2 --> DIR2
    GM2 --> PM2
    PM2 --> PE2
    GM2 --> FIN2
```

### Permission Matrix

| Module            | Super Admin | General Manager | Director | Project Manager    | Planning Engineer | Finance         |
| ----------------- | ----------- | --------------- | -------- | ------------------ | ----------------- | --------------- |
| **Dashboard**     | ✅ Full     | ✅ Full         | ✅ Full  | ✅ Own projects    | ✅ Own tasks      | ✅ Finance view |
| **Procurement**   | ✅ Full     | ✅ Full         | 👁️ Read  | ✅ Full            | 👁️ Read           | ✅ Full         |
| **Tasks**         | ✅ Full     | ✅ Full         | 👁️ Read  | ✅ Assign + manage | ✅ Own tasks      | 👁️ Read         |
| **Notes**         | ✅ Full     | ✅ Full         | 👁️ Read  | ✅ Full            | ✅ Full           | ❌              |
| **Meetings**      | ✅ Full     | ✅ Full         | ✅ Full  | ✅ Full            | ✅ Own            | ✅ View         |
| **Documents**     | ✅ Full     | ✅ Full         | 👁️ Read  | ✅ Full            | ✅ Upload         | ✅ View         |
| **Communication** | ✅ Full     | ✅ Full         | ✅ Full  | ✅ Full            | ✅ Full           | ✅ Full         |
| **Notifications** | ✅ Full     | ✅ Full         | ✅ Own   | ✅ Own             | ✅ Own            | ✅ Own          |
| **Admin Panel**   | ✅ Full     | ✅ Full         | ❌       | ❌                 | ❌                | ❌              |
| **Settings**      | ✅ Full     | ✅ Own          | ✅ Own   | ✅ Own             | ✅ Own            | ✅ Own          |

---

## 15. Project Structure

```
ICC_ProcuraX/
│
├── procurax_backend/               ← Node.js / Express 5 REST API
│   ├── app.js                      ← Express app entry point + middleware mounting
│   ├── package.json                ← Dependencies + npm scripts
│   ├── jest.config.js              ← Jest test configuration (ESM + coverage)
│   │
│   ├── api/v1/                     ← Versioned API route aggregators
│   │   ├── index.js                ← Mounts all /api/v1/* routes
│   │   ├── tasks.routes.js
│   │   ├── notes.routes.js
│   │   ├── meetings.routes.js
│   │   ├── notifications.routes.js
│   │   └── projects.routes.js
│   │
│   ├── core/                       ← ★ Core infrastructure (shared across all modules)
│   │   ├── index.js                ← Central export barrel
│   │   ├── errors/AppError.js      ← Custom error class with factory methods
│   │   ├── middleware/
│   │   │   ├── auth.middleware.js  ← JWT verify + RBAC requireRole
│   │   │   ├── errorHandler.js     ← Global async error handler
│   │   │   ├── httpLogger.middleware.js
│   │   │   ├── requestId.middleware.js
│   │   │   ├── rateLimiter.middleware.js
│   │   │   └── tracing.middleware.js
│   │   ├── services/
│   │   │   ├── task.service.js     ← TaskService (CRUD + stats)
│   │   │   ├── note.service.js     ← NoteService (CRUD + search)
│   │   │   ├── meeting.service.js  ← MeetingService (CRUD + conflict)
│   │   │   ├── project.service.js  ← ProjectService
│   │   │   ├── notification.service.js
│   │   │   ├── cache.service.js    ← Redis cache wrapper
│   │   │   ├── jobQueue.js         ← Bull queue factory
│   │   │   ├── redis.service.js    ← ioredis client
│   │   │   ├── metrics.service.js
│   │   │   └── performance.service.js
│   │   ├── validation/
│   │   │   ├── schemas.js          ← Centralised Joi schemas
│   │   │   └── validate.middleware.js
│   │   ├── logging/logger.js       ← Winston logger config
│   │   ├── config/
│   │   │   ├── database.js         ← MongoDB connection + index setup
│   │   │   └── envValidator.js     ← Startup environment validation
│   │   └── routes/health.routes.js
│   │
│   ├── auth/                       ← Authentication module
│   │   ├── routes/
│   │   ├── controllers/
│   │   ├── services/               ← AuthService (login, register, refresh)
│   │   └── middleware/
│   │
│   ├── admin-api/                  ← Admin-only elevated API
│   │   ├── routes/
│   │   │   ├── adminAuth.routes.js
│   │   │   ├── user.routes.js
│   │   │   ├── manager.routes.js
│   │   │   ├── project.routes.js
│   │   │   └── stats.routes.js
│   │   ├── controllers/
│   │   └── middleware/
│   │
│   ├── communication/              ← Real-time communication
│   │   ├── routes/
│   │   │   ├── chatRoutes.js
│   │   │   ├── callRoutes.js
│   │   │   ├── fileRoutes.js
│   │   │   ├── messageRoutes.js
│   │   │   ├── alertsRoutes.js
│   │   │   ├── presenceRoutes.js
│   │   │   └── typingRoutes.js
│   │   ├── controllers/
│   │   └── config/
│   │
│   ├── meetings/                   ← Smart calendar + meeting management
│   │   ├── routes/meetingRoutes.js
│   │   ├── controllers/
│   │   ├── services/               ← Conflict detection, Google Calendar sync
│   │   ├── models/
│   │   ├── middleware/
│   │   └── utils/
│   │
│   ├── notifications/              ← Multi-channel notification engine
│   │   ├── notification.routes.js
│   │   ├── notification.controller.js
│   │   ├── notification.service.js ← FCM + email dispatch
│   │   ├── notification.model.js
│   │   ├── scheduler.js            ← Cron jobs for timed notifications
│   │   └── README.md
│   │
│   ├── procument/                  ← Procurement scheduling
│   │   ├── routes/procurement.js
│   │   ├── services/
│   │   ├── middleware/
│   │   └── lib/
│   │
│   ├── tasks/                      ← Task management
│   │   ├── tasks.routes.js
│   │   ├── tasks.controller.js
│   │   └── tasks.model.js
│   │
│   ├── notes/                      ← Site notes
│   │   ├── notes.routes.js
│   │   ├── notes.controller.js
│   │   └── notes.model.js
│   │
│   ├── media/                      ← Document management (Cloudinary)
│   │   ├── routes/document.routes.js
│   │   ├── models/
│   │   └── middleware/
│   │
│   ├── buildassist/                ← AI chatbot
│   │   └── src/
│   │       ├── routes/chatbot.routes.js
│   │       ├── controllers/
│   │       └── services/
│   │
│   ├── settings/                   ← User + system settings
│   │   ├── routes/
│   │   │   ├── settings.routes.js
│   │   │   ├── user.routes.js
│   │   │   └── upload.routes.js
│   │   ├── controllers/
│   │   └── models/
│   │
│   ├── models/                     ← Shared Mongoose models
│   │   ├── User.js
│   │   └── Project.js
│   │
│   ├── config/                     ← Service configuration
│   │   ├── env.js                  ← dotenv loader
│   │   ├── firebase.js
│   │   ├── cloudinary.js
│   │   ├── jwt.js
│   │   ├── mailer.js
│   │   └── googleAuth.js
│   │
│   └── tests/                      ← Test suites
│       ├── setup.js
│       ├── unit/                   ← ~210 Jest unit tests
│       ├── integration/            ← ~17 integration tests
│       ├── security/               ← ~19 security tests
│       └── performance/            ← ~14 performance tests
│
├── procurax_frontend/              ← Flutter mobile application
│   ├── pubspec.yaml                ← Dependencies
│   ├── lib/
│   │   ├── main.dart               ← App entry + MultiProvider + routing
│   │   ├── pages/
│   │   │   ├── dashboard/          ← KPI dashboard
│   │   │   ├── procurement/        ← Procurement schedule screens
│   │   │   ├── tasks/              ← Task management screens
│   │   │   ├── notes/              ← Site notes screens
│   │   │   ├── meetings/           ← Smart calendar + meeting flows
│   │   │   │   └── features/smart_calendar/
│   │   │   ├── communication/      ← Chat hub screens
│   │   │   ├── documents/          ← Document browser
│   │   │   ├── notifications/      ← Notification centre
│   │   │   ├── build_assist/       ← AI chatbot UI
│   │   │   ├── settings/           ← User settings + theme
│   │   │   ├── log_in/             ← Login + forgot password
│   │   │   ├── sign_in/            ← Registration
│   │   │   └── get_started/        ← Onboarding
│   │   ├── services/               ← HTTP + Firebase service clients
│   │   │   ├── api_service.dart
│   │   │   ├── auth_service.dart
│   │   │   ├── chat_service.dart
│   │   │   ├── firebase_service.dart
│   │   │   ├── meetings_service.dart
│   │   │   ├── notes_service.dart
│   │   │   ├── procurement_service.dart
│   │   │   ├── tasks_service.dart
│   │   │   ├── permission_service.dart
│   │   │   └── push_notification_service.dart
│   │   ├── models/                 ← Dart data model classes
│   │   ├── components/             ← Reusable UI components
│   │   ├── widgets/                ← Shared widgets (AuthGate, loaders)
│   │   ├── theme/app_theme.dart    ← Design system (colours, fonts, spacing)
│   │   └── routes/app_routes.dart  ← Named route constants
│   ├── assets/                     ← App logos + images
│   │   ├── procurax.png
│   │   ├── icc_logo.png
│   │   └── procurax_app_logo.png
│   └── test/                       ← Flutter widget tests (~85 tests)
│
├── railway.json                    ← Railway deployment config
├── nixpacks.toml                   ← Nixpacks build config
├── package.json                    ← Root workspace config
├── ARCHITECTURE.md                 ← Detailed backend architecture doc
├── TESTING.md                      ← Full testing documentation
└── PERMISSIONS_DIAGRAMS.md        ← Role permission diagrams
```

---

## 16. Environment Variables

Create `procurax_backend/.env` with the following:

```env
# ─── Server ────────────────────────────────────────────────
NODE_ENV=development
PORT=5000

# ─── Database ──────────────────────────────────────────────
MONGO_URI=mongodb+srv://<user>:<pass>@cluster.mongodb.net/procurax

# ─── Authentication ────────────────────────────────────────
JWT_SECRET=<minimum-32-char-random-secret>
JWT_REFRESH_SECRET=<minimum-32-char-random-secret>
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# ─── Redis ─────────────────────────────────────────────────
REDIS_URL=redis://localhost:6379

# ─── Firebase (Push Notifications) ─────────────────────────
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@your-project.iam.gserviceaccount.com

# ─── Cloudinary (Media Storage) ────────────────────────────
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret

# ─── Google OAuth + Calendar ───────────────────────────────
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret
GOOGLE_REDIRECT_URI=http://localhost:5000/auth/google/callback

# ─── Email (Nodemailer) ────────────────────────────────────
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your@gmail.com
SMTP_PASS=your-app-password

# ─── Email (Resend — fallback) ─────────────────────────────
RESEND_API_KEY=re_...

# ─── Google Maps ───────────────────────────────────────────
GOOGLE_MAPS_API_KEY=AIza...
```

> ⚠️ **Security**: Never commit `.env` to version control. Use a secrets manager (Railway env vars, AWS Secrets Manager, etc.) in production.

---

## 17. Academic & Team Info

<div align="center">

| Field                      | Detail                                      |
| -------------------------- | ------------------------------------------- |
| **Module**                 | Software Development Group Project          |
| **Module Code**            | 5COSC021C                                   |
| **Institution**            | Informatics Institute of Technology (IIT)   |
| **University Affiliation** | University of Westminster                   |
| **Client**                 | International Construction Consortium (ICC) |
| **Platform**               | Android + iOS (Flutter)                     |
| **Backend**                | Node.js 22 + Express 5                      |

</div>

---

<div align="center">

<br/>

**ProcuraX** — Built with ❤️ for ICC by the IIT Software Development team

<br/>

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org)
[![MongoDB](https://img.shields.io/badge/MongoDB-47A248?style=for-the-badge&logo=mongodb&logoColor=white)](https://www.mongodb.com)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Redis](https://img.shields.io/badge/Redis-DC382D?style=for-the-badge&logo=redis&logoColor=white)](https://redis.io)
[![Railway](https://img.shields.io/badge/Railway-0B0D0E?style=for-the-badge&logo=railway&logoColor=white)](https://railway.app)

<br/>

_Informatics Institute of Technology · University of Westminster_

</div>
