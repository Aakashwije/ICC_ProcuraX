/**
 * Tasks Routes v1
 * 
 * RESTful API routes for task management with validation.
 */

import { Router } from "express";
import {
  authMiddleware,
  validateBody,
  validateObjectId,
  taskSchemas,
  asyncHandler,
  TaskService,
} from "../../core/index.js";

const router = Router();

// All routes require authentication
router.use(authMiddleware);

/**
 * GET /api/v1/tasks
 * Get all tasks for the authenticated user
 */
router.get(
  "/",
  asyncHandler(async (req, res) => {
    const { archived, status, priority } = req.query;
    const result = await TaskService.getTasks(req.userId, {
      archived: archived === "true",
      status,
      priority,
    });
    res.json({ success: true, ...result });
  })
);

/**
 * GET /api/v1/tasks/stats
 * Get task statistics for the authenticated user
 */
router.get(
  "/stats",
  asyncHandler(async (req, res) => {
    const stats = await TaskService.getTaskStats(req.userId);
    res.json({ success: true, stats });
  })
);

/**
 * GET /api/v1/tasks/:id
 * Get a specific task by ID
 */
router.get(
  "/:id",
  validateObjectId("id"),
  asyncHandler(async (req, res) => {
    const task = await TaskService.getTaskById(req.params.id, req.userId);
    res.json({ success: true, task });
  })
);

/**
 * POST /api/v1/tasks
 * Create a new task
 */
router.post(
  "/",
  validateBody(taskSchemas.create),
  asyncHandler(async (req, res) => {
    const task = await TaskService.createTask(req.validatedBody, req.userId);
    res.status(201).json({ success: true, task });
  })
);

/**
 * PUT /api/v1/tasks/:id
 * Update a task
 */
router.put(
  "/:id",
  validateObjectId("id"),
  validateBody(taskSchemas.update),
  asyncHandler(async (req, res) => {
    const task = await TaskService.updateTask(
      req.params.id,
      req.userId,
      req.validatedBody
    );
    res.json({ success: true, task });
  })
);

/**
 * PATCH /api/v1/tasks/:id/archive
 * Archive a task
 */
router.patch(
  "/:id/archive",
  validateObjectId("id"),
  asyncHandler(async (req, res) => {
    const task = await TaskService.archiveTask(req.params.id, req.userId);
    res.json({ success: true, task });
  })
);

/**
 * PATCH /api/v1/tasks/:id/restore
 * Restore an archived task
 */
router.patch(
  "/:id/restore",
  validateObjectId("id"),
  asyncHandler(async (req, res) => {
    const task = await TaskService.restoreTask(req.params.id, req.userId);
    res.json({ success: true, task });
  })
);

/**
 * DELETE /api/v1/tasks/:id
 * Delete a task permanently
 */
router.delete(
  "/:id",
  validateObjectId("id"),
  asyncHandler(async (req, res) => {
    await TaskService.deleteTask(req.params.id, req.userId);
    res.json({ success: true });
  })
);

export default router;
