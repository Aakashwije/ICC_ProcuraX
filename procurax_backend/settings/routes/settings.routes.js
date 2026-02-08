// src/routes/settings.routes.js - NO AUTH
import express from "express";
import { 
  getSettings, 
  updateSettings,
  updateMultipleSettings,
  getSettingByKey 
} from "../controllers/settings.controller.js";
// NO authMiddleware import!

const router = express.Router();

// Public routes - no authentication required
router.get("/", getSettings);
router.put("/bulk", updateMultipleSettings);
router.put("/:id", updateSettings);
router.get("/key/:key", getSettingByKey);

export default router;