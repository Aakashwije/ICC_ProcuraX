import { Router } from "express";
import { getStats } from "../controllers/stats.controller.js";
import { adminMiddleware as adminAuth } from "../../core/middleware/auth.middleware.js";

const router = Router();

router.get("/", adminAuth, getStats);

export default router;
