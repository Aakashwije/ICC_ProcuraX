/**
 * Notification Service (Core)
 *
 * Business logic layer for notification CRUD operations.
 * Wraps the existing NotificationService for creation helpers
 * and adds read/delete/stats operations via the data layer.
 */

import Notification from "../../notifications/notification.model.js";
import { AppError } from "../errors/AppError.js";
import logger from "../logging/logger.js";

class NotificationCoreService {
  /**
   * Get all notifications for a user
   */
  async getNotifications(userId, options = {}) {
    const { type, priority, isRead, page = 1, limit = 50 } = options;

    const query = { owner: userId };
    if (type) query.type = type;
    if (priority) query.priority = priority;
    if (isRead !== undefined) query.isRead = isRead;

    const notifications = await Notification.find(query)
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .populate("projectId", "name status")
      .populate("taskId", "title status")
      .populate("meetingId", "title startTime")
      .lean();

    const total = await Notification.countDocuments(query);
    const unreadCount = await Notification.countDocuments({
      owner: userId,
      isRead: false,
    });

    return {
      notifications,
      total,
      unreadCount,
      hasMore: total > (page - 1) * limit + notifications.length,
      pagination: { page, limit, total, pages: Math.ceil(total / limit) },
    };
  }

  /**
   * Get a single notification by ID
   */
  async getNotificationById(notificationId, userId) {
    const notification = await Notification.findOne({
      _id: notificationId,
      owner: userId,
    })
      .populate("projectId", "name status")
      .populate("taskId", "title status")
      .populate("meetingId", "title startTime");

    if (!notification) {
      throw AppError.notFound("Notification");
    }

    return notification;
  }

  /**
   * Mark a notification as read
   */
  async markAsRead(notificationId, userId) {
    const notification = await Notification.findOneAndUpdate(
      { _id: notificationId, owner: userId },
      { isRead: true },
      { new: true }
    );

    if (!notification) {
      throw AppError.notFound("Notification");
    }

    logger.debug("Notification marked as read", { notificationId, userId });
    return notification;
  }

  /**
   * Mark all notifications as read
   */
  async markAllAsRead(userId, type = null) {
    const query = { owner: userId, isRead: false };
    if (type) query.type = type;

    const result = await Notification.updateMany(query, { isRead: true });
    logger.info("All notifications marked as read", {
      userId,
      count: result.modifiedCount,
    });

    return { modifiedCount: result.modifiedCount };
  }

  /**
   * Delete a notification
   */
  async deleteNotification(notificationId, userId) {
    const notification = await Notification.findOneAndDelete({
      _id: notificationId,
      owner: userId,
    });

    if (!notification) {
      throw AppError.notFound("Notification");
    }

    logger.info("Notification deleted", { notificationId, userId });
    return { success: true };
  }

  /**
   * Get notification stats for a user
   */
  async getStats(userId) {
    const stats = await Notification.aggregate([
      { $match: { owner: userId } },
      {
        $group: {
          _id: { type: "$type", isRead: "$isRead" },
          count: { $sum: 1 },
        },
      },
    ]);

    const result = {
      total: 0,
      unread: 0,
      byType: {},
    };

    stats.forEach((s) => {
      const type = s._id.type;
      if (!result.byType[type]) result.byType[type] = { total: 0, unread: 0 };
      result.byType[type].total += s.count;
      result.total += s.count;
      if (!s._id.isRead) {
        result.byType[type].unread += s.count;
        result.unread += s.count;
      }
    });

    return result;
  }
}

export default new NotificationCoreService();
