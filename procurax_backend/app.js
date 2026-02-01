// procurax_backend/app.js
import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import mongoose from "mongoose";
import procurementRoutes from "./procument/routes/procurement.js";
import notesRoutes from "./notes/notes.routes.js";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const mongoUri =
	process.env.MONGODB_URI ||
	process.env.MONGO_URI ||
	"mongodb://127.0.0.1:27017/procurax";

mongoose
	.connect(mongoUri)
	.then(() => console.log("MongoDB connected"))
	.catch((err) => {
		console.error("MongoDB connection error (falling back to memory):", err);
	});

process.on("unhandledRejection", (err) => {
	console.error("Unhandled rejection:", err);
});

process.on("uncaughtException", (err) => {
	console.error("Uncaught exception:", err);
	process.exit(1);
});

// mount API under /api
app.use("/api", procurementRoutes);
app.use("/api/notes", notesRoutes); 

// basic health
app.get("/", (req, res) => res.send("ProcuraX backend running"));

const port = process.env.PORT || 3000;
console.log("Starting ProcuraX backend...");
const server = app.listen(port, () => {
	console.log(`Server listening on ${port}`);
});
server.on("error", (err) => {
	console.error("Server failed to start:", err);
	process.exit(1);
});
