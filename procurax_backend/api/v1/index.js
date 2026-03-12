/**
 * API v1 Routes Index
 * 
 * Aggregates all v1 API routes for centralized mounting.
 */

import { Router } from "express";

// Import route modules
import tasksRoutes from "./tasks.routes.js";
import notesRoutes from "./notes.routes.js";
import meetingsRoutes from "./meetings.routes.js";

const router = Router();

// Mount v1 routes
router.use("/tasks", tasksRoutes);
router.use("/notes", notesRoutes);
router.use("/meetings", meetingsRoutes);

export default router;
