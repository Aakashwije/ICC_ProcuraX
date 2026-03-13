import mongoose from 'mongoose';
import Notification from './notification.model.js';

// Helper to convert userId string to ObjectId with error handling
const toObjectId = (userId) => {
  try {
    return new mongoose.Types.ObjectId(userId);
  } catch {
    throw new Error('Invalid user ID format');
  }
};

// Get all notifications for the authenticated user
export const getUserNotifications = async (req, res) => {
  try {
    const userId = req.userId;
    const { type, priority, isRead, limit = 50, skip = 0 } = req.query;

    console.log('[Notifications] Fetching for user:', userId);

    const ownerObjectId = toObjectId(userId);

    // Build query
    const query = { owner: ownerObjectId };
    
    if (type) query.type = type;
    if (priority) query.priority = priority;
    if (isRead !== undefined) query.isRead = isRead === 'true';

    console.log('[Notifications] Query:', JSON.stringify(query));

    const notifications = await Notification.find(query)
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(skip))
      .populate('projectId', 'name status')
      .populate('taskId', 'title status')
      .populate('meetingId', 'title startTime')
      .lean();

    console.log('[Notifications] Found:', notifications.length);

    const total = await Notification.countDocuments(query);
    const unreadCount = await Notification.countDocuments({ owner: ownerObjectId, isRead: false });

    res.json({
      notifications,
      total,
      unreadCount,
      hasMore: total > parseInt(skip) + notifications.length
    });
  } catch (error) {
    console.error('Error fetching notifications:', error);
    res.status(500).json({ error: 'Failed to fetch notifications' });
  }
};

// Get a single notification by ID
export const getNotificationById = async (req, res) => {
  try {
    const userId = req.userId;
    const { id } = req.params;

    const notification = await Notification.findOne({ _id: id, owner: toObjectId(userId) })
      .populate('projectId', 'name status')
      .populate('taskId', 'title status')
      .populate('meetingId', 'title startTime');

    if (!notification) {
      return res.status(404).json({ error: 'Notification not found' });
    }

    res.json(notification);
  } catch (error) {
    console.error('Error fetching notification:', error);
    res.status(500).json({ error: 'Failed to fetch notification' });
  }
};

// Create a new notification
export const createNotification = async (req, res) => {
  try {
    const userId = req.userId;
    const {
      title,
      message,
      type,
      priority,
      projectName,
      projectStatus,
      projectId,
      taskId,
      meetingId,
      procurementId,
      metadata,
      actionUrl
    } = req.body;

    // Validate required fields
    if (!title || !message || !type) {
      return res.status(400).json({ error: 'Title, message, and type are required' });
    }

    const notification = new Notification({
      owner: userId,
      title,
      message,
      type,
      priority: priority || 'medium',
      projectName,
      projectStatus,
      projectId,
      taskId,
      meetingId,
      procurementId,
      metadata,
      actionUrl
    });

    await notification.save();

    res.status(201).json(notification);
  } catch (error) {
    console.error('Error creating notification:', error);
    res.status(500).json({ error: 'Failed to create notification' });
  }
};

// Mark a notification as read
export const markNotificationAsRead = async (req, res) => {
  try {
    const userId = req.userId;
    const { id } = req.params;

    const notification = await Notification.findOneAndUpdate(
      { _id: id, owner: toObjectId(userId) },
      { isRead: true },
      { new: true }
    );

    if (!notification) {
      return res.status(404).json({ error: 'Notification not found' });
    }

    res.json(notification);
  } catch (error) {
    console.error('Error marking notification as read:', error);
    res.status(500).json({ error: 'Failed to update notification' });
  }
};

// Mark all notifications as read
export const markAllAsRead = async (req, res) => {
  try {
    const userId = req.userId;
    const { type } = req.query;

    const query = { owner: toObjectId(userId), isRead: false };
    if (type) query.type = type;

    const result = await Notification.updateMany(
      query,
      { isRead: true }
    );

    res.json({
      message: 'All notifications marked as read',
      modifiedCount: result.modifiedCount
    });
  } catch (error) {
    console.error('Error marking all as read:', error);
    const statusCode = error.message?.includes('Invalid') ? 400 : 500;
    res.status(statusCode).json({ error: error.message || 'Failed to update notifications' });
  }
};

// Delete a notification
export const deleteNotification = async (req, res) => {
  try {
    const userId = req.userId;
    const { id } = req.params;

    const notification = await Notification.findOneAndDelete({
      _id: id,
      owner: toObjectId(userId)
    });

    if (!notification) {
      return res.status(404).json({ error: 'Notification not found' });
    }

    res.json({ message: 'Notification deleted successfully' });
  } catch (error) {
    console.error('Error deleting notification:', error);
    res.status(500).json({ error: 'Failed to delete notification' });
  }
};

// Delete all notifications
export const deleteAllNotifications = async (req, res) => {
  try {
    const userId = req.userId;
    const { type, isRead } = req.query;

    const query = { owner: toObjectId(userId) };
    if (type) query.type = type;
    if (isRead !== undefined) query.isRead = isRead === 'true';

    const result = await Notification.deleteMany(query);

    res.json({
      message: 'Notifications deleted successfully',
      deletedCount: result.deletedCount
    });
  } catch (error) {
    console.error('Error deleting notifications:', error);
    res.status(500).json({ error: 'Failed to delete notifications' });
  }
};

// Get notification statistics
export const getNotificationStats = async (req, res) => {
  try {
    const userId = req.userId;

    const ownerObjId = toObjectId(userId);

    const stats = await Notification.aggregate([
      { $match: { owner: ownerObjId } },
      {
        $group: {
          _id: '$type',
          total: { $sum: 1 },
          unread: {
            $sum: { $cond: [{ $eq: ['$isRead', false] }, 1, 0] }
          }
        }
      }
    ]);

    const priorityStats = await Notification.aggregate([
      { $match: { owner: ownerObjId, isRead: false } },
      {
        $group: {
          _id: '$priority',
          count: { $sum: 1 }
        }
      }
    ]);

    const totalUnread = await Notification.countDocuments({
      owner: ownerObjId,
      isRead: false
    });

    res.json({
      byType: stats,
      byPriority: priorityStats,
      totalUnread
    });
  } catch (error) {
    console.error('Error fetching notification stats:', error);
    res.status(500).json({ error: 'Failed to fetch statistics' });
  }
};

// Bulk update notifications
export const bulkUpdateNotifications = async (req, res) => {
  try {
    const userId = req.userId;
    const { ids, isRead } = req.body;

    if (!ids || !Array.isArray(ids) || ids.length === 0) {
      return res.status(400).json({ error: 'IDs array is required' });
    }

    const result = await Notification.updateMany(
      { _id: { $in: ids }, owner: toObjectId(userId) },
      { isRead: isRead !== undefined ? isRead : true }
    );

    res.json({
      message: 'Notifications updated successfully',
      modifiedCount: result.modifiedCount
    });
  } catch (error) {
    console.error('Error bulk updating notifications:', error);
    res.status(500).json({ error: 'Failed to update notifications' });
  }
};

// Bulk delete notifications
export const bulkDeleteNotifications = async (req, res) => {
  try {
    const userId = req.userId;
    const { ids } = req.body;

    if (!ids || !Array.isArray(ids) || ids.length === 0) {
      return res.status(400).json({ error: 'IDs array is required' });
    }

    const result = await Notification.deleteMany({
      _id: { $in: ids },
      owner: toObjectId(userId)
    });

    res.json({
      message: 'Notifications deleted successfully',
      deletedCount: result.deletedCount
    });
  } catch (error) {
    console.error('Error bulk deleting notifications:', error);
    res.status(500).json({ error: 'Failed to delete notifications' });
  }
};
