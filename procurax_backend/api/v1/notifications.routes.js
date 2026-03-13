/**
 * Notifications Routes v1
 *
 * RESTful API routes for notification management with validation.
 * Architecture: Route → Controller (asyncHandler) → Service → Model
 */

import { Router } from "express";
import {
  authMiddleware,
  validateObjectId,
  asyncHandler,
  NotificationCoreService,
} from "../../core/index.js";

const router = Router();

// All routes require authentication
router.use(authMiddleware);

/**
 * GET /api/v1/notifications
 * Get all notifications for the authenticated user
 */
router.get(
  "/",
  asyncHandler(async (req, res) => {
    const { type, priority, isRead, page, limit } = req.query;
    const result = await NotificationCoreService.getNotifications(req.userId, {
      type,
      priority,
      isRead: isRead !== undefined ? isRead === "true" : undefined,
      page: page ? parseInt(page) : undefined,
      limit: limit ? parseInt(limit) : undefined,
    });
    res.json({ success: true, ...result });
  })
);

/**
 * GET /api/v1/notifications/stats
 * Get notification statistics
 */
router.get(
  "/stats",
  asyncHandler(async (req, res) => {
    const stats = await NotificationCoreService.getStats(req.userId);
    res.json({ success: true, stats });
  })
);

/**
 * GET /api/v1/notifications/:id
 * Get a specific notification
 */
router.get(
  "/:id",
  validateObjectId("id"),
  asyncHandler(async (req, res) => {
    const notification = await NotificationCoreService.getNotificationById(
      req.params.id,
      req.userId
    );
    res.json({ success: true, notification });
  })
);

/**
 * PATCH /api/v1/notifications/:id/read
 * Mark a notification as read
 */
router.patch(
  "/:id/read",
  validateObjectId("id"),
  asyncHandler(async (req, res) => {
    const notification = await NotificationCoreService.markAsRead(
      req.params.id,
      req.userId
    );
    res.json({ success: true, notification });
  })
);

/**
 * PATCH /api/v1/notifications/mark-all/read
 * Mark all notifications as read
 */
router.patch(
  "/mark-all/read",
  asyncHandler(async (req, res) => {
    const { type } = req.query;
    const result = await NotificationCoreService.markAllAsRead(req.userId, type);
    res.json({ success: true, ...result });
  })
);

/**
 * DELETE /api/v1/notifications/:id
 * Delete a notification
 */
router.delete(
  "/:id",
  validateObjectId("id"),
  asyncHandler(async (req, res) => {
    await NotificationCoreService.deleteNotification(req.params.id, req.userId);
    res.json({ success: true });
  })
);

export default router;
