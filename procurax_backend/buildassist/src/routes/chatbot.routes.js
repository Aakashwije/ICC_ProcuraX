import express from "express";
import { chatWithAI } from "../controllers/chatController.js";

const router = express.Router();

// POST /api/chatbot
router.post("/", chatWithAI);

// GET /api/chatbot/health
router.get("/health", (req, res) => {
  res.json({ status: "Chatbot API is running" });
});

export default router;