// src/routes/settings.routes.js
import express from "express";
import authMiddleware from "../../auth/auth.middleware.js";
import { 
  getSettings, 
  updateSettings,
  updateMultipleSettings,
  getSettingByKey 
} from "../controllers/settings.controller.js";

const router = express.Router();

// All settings routes require a valid JWT
router.get("/", authMiddleware, getSettings);
router.put("/bulk", authMiddleware, updateMultipleSettings);
router.put("/:id", authMiddleware, updateSettings);
router.get("/key/:key", authMiddleware, getSettingByKey);

export default router;