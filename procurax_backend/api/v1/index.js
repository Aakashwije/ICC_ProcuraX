/**
 * API v1 Routes Index
 *
 * Aggregates all v1 API routes for centralized mounting.
 * All routes under /api/v1/ use the service layer architecture
 * with Joi validation and unified error handling.
 */

import { Router } from "express";

// Import route modules
import tasksRoutes from "./tasks.routes.js";
import notesRoutes from "./notes.routes.js";
import meetingsRoutes from "./meetings.routes.js";
import notificationsRoutes from "./notifications.routes.js";
import projectsRoutes from "./projects.routes.js";

const router = Router();

// Mount v1 routes
router.use("/tasks", tasksRoutes);
router.use("/notes", notesRoutes);
router.use("/meetings", meetingsRoutes);
router.use("/notifications", notificationsRoutes);
router.use("/projects", projectsRoutes);

export default router;
