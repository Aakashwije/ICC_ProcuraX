import { Router } from "express";
import { getStats } from "../controllers/stats.controller.js";
import adminAuth from "../middleware/adminAuth.middleware.js";

const router = Router();

router.get("/", adminAuth, getStats);

export default router;
