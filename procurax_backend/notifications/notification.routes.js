import express from 'express';
import {
  getUserNotifications,
  getNotificationById,
  createNotification,
  markNotificationAsRead,
  markAllAsRead,
  deleteNotification,
  deleteAllNotifications,
  getNotificationStats,
  bulkUpdateNotifications,
  bulkDeleteNotifications
} from './notification.controller.js';
import authMiddleware from '../auth/auth.middleware.js';

const router = express.Router();

// All routes require authentication
router.use(authMiddleware);

// Get all notifications for authenticated user (with filtering)
// Query params: type, priority, isRead, limit, skip
router.get('/', getUserNotifications);

// Get notification statistics
router.get('/stats', getNotificationStats);

// Get a single notification by ID
router.get('/:id', getNotificationById);

// Create a new notification
router.post('/', createNotification);

// Mark a notification as read
router.patch('/:id/read', markNotificationAsRead);

// Mark all notifications as read (optionally filtered by type)
// Query params: type
router.patch('/mark-all/read', markAllAsRead);

// Bulk update notifications
// Body: { ids: [], isRead: true/false }
router.patch('/bulk/update', bulkUpdateNotifications);

// Delete a notification
router.delete('/:id', deleteNotification);

// Delete all notifications (optionally filtered by type or read status)
// Query params: type, isRead
router.delete('/bulk/all', deleteAllNotifications);

// Bulk delete notifications
// Body: { ids: [] }
router.delete('/bulk/delete', bulkDeleteNotifications);

export default router;
