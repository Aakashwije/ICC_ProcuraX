// procurax_backend/app.js
import "./config/env.js";
import path from "path";
import { fileURLToPath } from "url";
import express from "express";
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
import cors from "cors";
import mongoose from "mongoose";

// ===== CORE INFRASTRUCTURE =====
import {
  errorHandler,
  notFoundHandler,
  requestIdMiddleware,
  httpLogger,
  apiLimiter,
  authLimiter,
  logger,
  jobQueue,
} from "./core/index.js";

import NotificationService from "./notifications/notification.service.js";

// ===== API v1 ROUTES (versioned, validated, service-layer) =====
import v1Routes from "./api/v1/index.js";

// Existing module routes (backward compatibility)
import procurementRoutes from "./procument/routes/procurement.js";
import notesRoutes from "./notes/notes.routes.js";
import tasksRoutes from "./tasks/tasks.routes.js";
import settingsRoutes from "./settings/routes/settings.routes.js";
import settingsUserRoutes from "./settings/routes/user.routes.js";
import meetingRoutes from "./meetings/routes/meetingRoutes.js";
import authRoutes from "./auth/routes/auth.routes.js";

// ===== COMMUNICATION MODULES =====
import userRoutes from "./communication/routes/userRoutes.js";
import callRoutes from "./communication/routes/callRoutes.js";
import chatRoutes from "./communication/routes/chatRoutes.js";
import fileRoutes from "./communication/routes/fileRoutes.js";
import messageRoutes from "./communication/routes/messageRoutes.js";
import alertsRoutes from "./communication/routes/alertsRoutes.js";
import presenceRoutes from "./communication/routes/presenceRoutes.js";
import typingRoutes from "./communication/routes/typingRoutes.js";
import adminAuthRoutes from "./admin-api/routes/adminAuth.routes.js";
import adminManagerRoutes from "./admin-api/routes/manager.routes.js";
import adminProjectRoutes from "./admin-api/routes/project.routes.js";
import adminStatsRoutes from "./admin-api/routes/stats.routes.js";
import adminUserRoutes from "./admin-api/routes/user.routes.js";
import userProfileRoutes from "./user/routes/user.routes.js";
// =================================

// ===== DOCUMENTS MODULE =====
import documentRoutes from "./media/routes/document.routes.js";

// ===========================

// ===== NOTIFICATIONS MODULE =====
import notificationRoutes from "./notifications/notification.routes.js";


// ===== CHATBOT MODULE =====
import chatbotRoutes from "./buildassist/src/routes/chatbot.routes.js";

// ================================

// ===== UPLOAD ROUTES =====
import uploadRoutes from "./settings/routes/upload.routes.js";	

// =========================

// ===== SETTINGS USER ROUTES =====
import settingsUserProfileRoutes from "./settings/routes/user.routes.js";

// =========================	

const app = express();

// ===== GLOBAL MIDDLEWARE PIPELINE =====
// 1. Request ID — assigns correlation ID to every request
app.use(requestIdMiddleware);

// 2. HTTP Logger — structured request/response logging
app.use(httpLogger);

// 3. Security & Parsing
app.use(cors());
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true }));

// 4. Global Rate Limiter — protects against DDoS
app.use("/api", apiLimiter);
app.use("/auth", authLimiter);

// Static file serving for uploaded documents
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// ===== ASYNC JOB QUEUE SETUP =====
// Register notification job handler for async processing
jobQueue.registerHandler("send_notification", async (payload) => {
  const { userId, type, data } = payload;
  switch (type) {
    case "task":
      await NotificationService.createTaskNotification(userId, data);
      break;
    case "meeting":
      await NotificationService.createMeetingNotification(userId, data);
      break;
    case "project":
      await NotificationService.createProjectNotification(userId, data);
      break;
    default:
      await NotificationService.createGeneralNotification(userId, data);
  }
});

logger.info("Async job queue initialized with notification handler");

// MongoDB Connection
const mongoUri =
	process.env.MONGODB_URI ||
	process.env.MONGO_URI ||
	"mongodb://127.0.0.1:27017/procurax";

mongoose
	.connect(mongoUri)
	.then(() => {
		logger.info("✅ MongoDB connected", { uri: mongoUri.replace(/\/\/.*@/, "//***@") });
	})
	.catch((err) => {
		logger.error("❌ MongoDB connection error", { error: err.message });
	});

// Global process handlers
process.on("unhandledRejection", (err) => {
	logger.error("Unhandled rejection", { error: err?.message, stack: err?.stack });
});

process.on("uncaughtException", (err) => {
	logger.error("Uncaught exception", { error: err.message, stack: err.stack });
	process.exit(1);
});

// ===== VERSIONED API ROUTES (v1) =====
// New architecture: validated, service-layer backed
app.use("/api/v1", v1Routes);

// ===== UPLOAD ROUTES =====
app.use("/api/upload", uploadRoutes);
// =================================

// ===== EXISTING CORE ROUTES (backward compatibility) =====
app.use("/api", procurementRoutes);
app.use("/api/notes", notesRoutes);
app.use("/api/tasks", tasksRoutes);
app.use("/api/meetings", meetingRoutes);
app.use("/api/settings", settingsRoutes);
app.use("/api/settings/users", settingsUserRoutes);
app.use("/auth", authRoutes);

// ===== SETTINGS USER ROUTES =====
app.use("/api/users", settingsUserProfileRoutes);	
// =========================

// ===== COMMUNICATION MODULE ROUTES =====
app.use("/api/communication/users", userRoutes);
app.use("/api/calls", callRoutes);
app.use("/api/chats", chatRoutes);
app.use("/api/files", fileRoutes);
app.use("/api/messages", messageRoutes);
app.use("/api/alerts", alertsRoutes);
app.use("/api/presence", presenceRoutes);
app.use("/api/typing", typingRoutes);
app.use("/admin-auth", adminAuthRoutes);
app.use("/admin-managers", adminManagerRoutes);
app.use("/admin-projects", adminProjectRoutes);
app.use("/admin-stats", adminStatsRoutes);
app.use("/admin-users", adminUserRoutes);

/* User self-service profile route — GET /api/user/profile */
app.use("/api/user", userProfileRoutes);



// ===== DOCUMENTS MODULE ROUTES =====
app.use("/api/documents", documentRoutes);

// =======================================

// ===== NOTIFICATIONS MODULE ROUTES =====
app.use("/api/notifications", notificationRoutes);

// ========================================

// ===== CHATBOT MODULE ROUTES =====
app.use("/api/buildassist", chatbotRoutes);

// =================================

// Basic health route with system info
app.get("/", (req, res) => res.json({
  status: "running",
  service: "ProcuraX Backend",
  version: "1.0.0",
  timestamp: new Date().toISOString(),
  uptime: process.uptime(),
}));

// Health check endpoint
app.get("/health", (req, res) => res.json({
  status: "healthy",
  db: mongoose.connection.readyState === 1 ? "connected" : "disconnected",
  uptime: process.uptime(),
  memory: process.memoryUsage(),
}));

// Firebase diagnostic endpoint (temporary - remove after debugging)
app.get("/debug/firebase", async (req, res) => {
  const { default: firebaseAdmin } = await import("firebase-admin");
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  const info = {
    envVarExists: !!raw,
    envVarLength: raw ? raw.length : 0,
    envVarStart: raw ? raw.substring(0, 50) : "N/A",
    envVarEnd: raw ? raw.substring(raw.length - 50) : "N/A",
  };
  try {
    const parsed = JSON.parse(raw || "{}");
    info.parseSuccess = true;
    info.projectId = parsed.project_id || "MISSING";
    info.clientEmail = parsed.client_email || "MISSING";
    info.hasPrivateKey = !!parsed.private_key;
    info.privateKeyLength = parsed.private_key ? parsed.private_key.length : 0;
    info.privateKeyStart = parsed.private_key ? parsed.private_key.substring(0, 40) : "N/A";
    info.type = parsed.type || "MISSING";
  } catch (e) {
    info.parseSuccess = false;
    info.parseError = e.message;
  }
  info.firebaseAppsCount = firebaseAdmin.apps.length;
  res.json(info);
});

// ===== ERROR HANDLING (must be last) =====
// 404 handler — catches unmatched routes
app.use(notFoundHandler);

// Global error handler — catches ALL errors from asyncHandler and middleware
app.use(errorHandler);

// Start server
const port = process.env.PORT || 5002;

const server = app.listen(port, () => {
	logger.info(`✅ Server listening on port ${port}`, {
		env: process.env.NODE_ENV || "development",
		port,
	});
});

server.on("error", (err) => {
	logger.error("❌ Server failed to start", { error: err.message });
	process.exit(1);
});
