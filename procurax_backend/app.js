// procurax_backend/app.js
import "./config/env.js";
import path from "path";
import { fileURLToPath } from "url";
import express from "express";
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
import cors from "cors";
import mongoose from "mongoose";

// Existing modules
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

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// DEBUG: log incoming requests (helps diagnose missing routes)
app.use((req, res, next) => {
  console.log(`[REQ] ${req.method} ${req.url}`);
  next();
});

// Static file serving for uploaded documents
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// MongoDB Connection
const mongoUri =
	process.env.MONGODB_URI ||
	process.env.MONGO_URI ||
	"mongodb://127.0.0.1:27017/procurax";

mongoose
	.connect(mongoUri)
	.then(() => console.log("MongoDB connected"))
	.catch((err) => {
		console.error("MongoDB connection error:", err);
	});

// Global process handlers
process.on("unhandledRejection", (err) => {
	console.error("Unhandled rejection:", err);
});

process.on("uncaughtException", (err) => {
	console.error("Uncaught exception:", err);
	process.exit(1);
});

// ===== EXISTING CORE ROUTES =====
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
app.use("/api/users", userRoutes);
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



// ===== UPLOAD ROUTES =====
app.use("/api/upload", uploadRoutes);

// =================================

// ===== DOCUMENTS MODULE ROUTES =====
app.use("/api/documents", documentRoutes);

// =======================================

// ===== NOTIFICATIONS MODULE ROUTES =====
app.use("/api/notifications", notificationRoutes);

// ========================================

// ===== CHATBOT MODULE ROUTES =====
app.use("/api/buildassist", chatbotRoutes);

// =================================

// Basic health route
app.get("/", (req, res) => res.send("ProcuraX backend running"));

// Print all registered routes (for debugging)
const listRoutes = (app) => {
  if (!app._router || !app._router.stack) {
    console.log('No routes registered yet (app._router is undefined)');
    return;
  }

  const routes = [];
  app._router.stack.forEach((middleware) => {
    if (middleware.route) {
      const methods = Object.keys(middleware.route.methods)
        .map((m) => m.toUpperCase())
        .join(',');
      routes.push(`${methods} ${middleware.route.path}`);
    } else if (middleware.name === 'router' && middleware.handle && middleware.handle.stack) {
      middleware.handle.stack.forEach((handler) => {
        if (handler.route) {
          const methods = Object.keys(handler.route.methods)
            .map((m) => m.toUpperCase())
            .join(',');
          routes.push(`${methods} ${handler.route.path}`);
        }
      });
    }
  });
  console.log('Registered routes:\n' + routes.join('\n'));
};

listRoutes(app);

// Handle unknown routes
app.use((req, res) => {
	res.status(404).json({ error: "Route not found" });
});

// Global error handler
app.use((err, req, res, next) => {
	console.error(err.stack);
	res.status(500).json({ error: "Internal Server Error" });
});

// Start server
const port = process.env.PORT || 3000;
console.log("Starting ProcuraX backend...");

const server = app.listen(port, () => {
	console.log(`Server listening on ${port}`);
});

server.on("error", (err) => {
	console.error("Server failed to start:", err);
	process.exit(1);
});
