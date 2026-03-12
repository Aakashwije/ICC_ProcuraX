import express from "express";
import { chatWithAI } from "../controllers/chatController.js";

const router = express.Router();

// POST /api/buildassist - no authentication required
router.post("/", chatWithAI);

// GET /api/buildassist/health
router.get("/health", (req, res) => {
  res.json({ status: "BuildAssist API is running" });
});

export default router;