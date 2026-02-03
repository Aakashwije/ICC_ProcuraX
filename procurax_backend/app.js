// procurax_backend/app.js
import "./config/env.js";
import express from "express";
import cors from "cors";
import mongoose from "mongoose";

// Existing modules
import procurementRoutes from "./procument/routes/procurement.js";
import notesRoutes from "./notes/notes.routes.js";

// ===== COMMUNICATION MODULES =====
import userRoutes from "./communication/routes/userRoutes.js";
import callRoutes from "./communication/routes/callRoutes.js";
import chatRoutes from "./communication/routes/chatRoutes.js";
import fileRoutes from "./communication/routes/fileRoutes.js";
import messageRoutes from "./communication/routes/messageRoutes.js";
import alertsRoutes from "./communication/routes/alertsRoutes.js";
import presenceRoutes from "./communication/routes/presenceRoutes.js";
import typingRoutes from "./communication/routes/typingRoutes.js";
// =================================
const app = express();

// Middleware
app.use(cors());
app.use(express.json());

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

// ===== COMMUNICATION MODULE ROUTES =====
app.use("/api/users", userRoutes);
app.use("/api/calls", callRoutes);
app.use("/api/chats", chatRoutes);
app.use("/api/files", fileRoutes);
app.use("/api/messages", messageRoutes);
app.use("/api/alerts", alertsRoutes);
app.use("/api/presence", presenceRoutes);
app.use("/api/typing", typingRoutes);
// =======================================

// Basic health route
app.get("/", (req, res) => res.send("ProcuraX backend running"));

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
