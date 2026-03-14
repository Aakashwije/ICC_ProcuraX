import express from "express";
import { chatWithAI } from "../controllers/chatController.js";
import { optionalAuth } from "../../../core/middleware/auth.middleware.js";

const router = express.Router();

// POST /api/buildassist - optional authentication (allows scheduling for logged-in users)
router.post("/", optionalAuth, chatWithAI);

// GET /api/buildassist/health
router.get("/health", (req, res) => {
  res.json({ status: "BuildAssist API is running" });
});

export default router;