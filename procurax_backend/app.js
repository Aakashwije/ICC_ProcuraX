// procurax_backend/app.js
import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import procurementRoutes from "./procument/routes/procurement.js";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

process.on("unhandledRejection", (err) => {
	console.error("Unhandled rejection:", err);
});

process.on("uncaughtException", (err) => {
	console.error("Uncaught exception:", err);
	process.exit(1);
});

// mount API under /api
app.use("/api", procurementRoutes);

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
