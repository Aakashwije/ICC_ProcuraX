/**
 * Tasks Controller (Refactored)
 *
 * Thin controller layer — delegates ALL business logic to TaskService.
 * The controller only handles HTTP concerns:
 *   1. Extracting parameters from req
 *   2. Calling the service
 *   3. Sending the response
 *
 * Architecture: Controller → Service → Model (3-tier)
 */

import TaskService from "../core/services/task.service.js";
import NotificationService from "../notifications/notification.service.js";
import { asyncHandler } from "../core/middleware/errorHandler.js";
import logger from "../core/logging/logger.js";

/**
 * POST /api/tasks — Create a new task
 */
export const createTask = asyncHandler(async (req, res) => {
  const task = await TaskService.createTask(req.body, req.userId);

  // Fire-and-forget notification
  NotificationService.createTaskNotification(req.userId, {
    taskTitle: task.title,
    taskId: task.id,
    action: "created",
  }).catch((err) => logger.error("Task notification failed", { err: err.message }));

  res.status(201).json(task);
});

/**
 * GET /api/tasks — Get all tasks for the authenticated user
 */
export const getTasks = asyncHandler(async (req, res) => {
  const { archived, status, priority, page, limit } = req.query;

  const result = await TaskService.getTasks(req.userId, {
    archived: archived === "true",
    status,
    priority,
    page: page ? parseInt(page) : undefined,
    limit: limit ? parseInt(limit) : undefined,
  });

  // Return flat array for backward compatibility with frontend
  res.json(result.tasks);
});

/**
 * GET /api/tasks/:id — Get a single task
 */
export const getTaskById = asyncHandler(async (req, res) => {
  const task = await TaskService.getTaskById(req.params.id, req.userId);
  res.json(task);
});

/**
 * PUT /api/tasks/:id — Update a task
 */
export const updateTask = asyncHandler(async (req, res) => {
  const task = await TaskService.updateTask(req.params.id, req.userId, req.body);

  // Fire-and-forget notification for status changes
  if (req.body.status) {
    const action = req.body.status === "done" ? "completed" : "updated";
    NotificationService.createTaskNotification(req.userId, {
      taskTitle: task.title,
      taskId: task.id,
      action,
    }).catch((err) => logger.error("Task update notification failed", { err: err.message }));
  }

  res.json(task);
});

/**
 * PATCH /api/tasks/:id/archive — Archive a task
 */
export const archiveTask = asyncHandler(async (req, res) => {
  const task = await TaskService.archiveTask(req.params.id, req.userId);
  res.json(task);
});

/**
 * PATCH /api/tasks/:id/restore — Restore an archived task
 */
export const restoreTask = asyncHandler(async (req, res) => {
  const task = await TaskService.restoreTask(req.params.id, req.userId);
  res.json(task);
});

/**
 * DELETE /api/tasks/:id — Delete a task permanently
 */
export const deleteTask = asyncHandler(async (req, res) => {
  await TaskService.deleteTask(req.params.id, req.userId);
  res.json({ success: true });
});

/**
 * GET /api/tasks/stats — Get task statistics
 */
export const getTaskStats = asyncHandler(async (req, res) => {
  const stats = await TaskService.getTaskStats(req.userId);
  res.json({ success: true, stats });
});
