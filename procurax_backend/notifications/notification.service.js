import Notification from './notification.model.js';

/**
 * Notification Service
 * Helper functions to create notifications from different modules
 */

class NotificationService {
  /**
   * Create a project notification
   */
  static async createProjectNotification(userId, { projectName, projectStatus, projectId, action, details }) {
    const titles = {
      created: `New Project: ${projectName}`,
      updated: `Project Updated: ${projectName}`,
      completed: `Project Completed: ${projectName}`,
      assigned: `You've been assigned to: ${projectName}`,
      statusChanged: `Project Status Changed: ${projectName}`
    };

    const messages = {
      created: `A new project "${projectName}" has been created.`,
      updated: `The project "${projectName}" has been updated. ${details || ''}`,
      completed: `The project "${projectName}" has been marked as completed.`,
      assigned: `You have been assigned to the project "${projectName}".`,
      statusChanged: `The project "${projectName}" status changed to ${projectStatus}.`
    };

    return await Notification.create({
      owner: userId,
      title: titles[action] || `Project: ${projectName}`,
      message: messages[action] || details || `Update for project "${projectName}".`,
      type: 'projects',
      priority: action === 'assigned' ? 'high' : 'medium',
      projectName,
      projectStatus,
      projectId
    });
  }

  /**
   * Create a task notification
   */
  static async createTaskNotification(userId, { taskTitle, taskId, action, dueDate, assignedBy }) {
    const titles = {
      created: `New Task: ${taskTitle}`,
      assigned: `Task Assigned: ${taskTitle}`,
      updated: `Task Updated: ${taskTitle}`,
      completed: `Task Completed: ${taskTitle}`,
      dueToday: `Due Today: ${taskTitle}`,
      overdue: `Overdue: ${taskTitle}`
    };

    const messages = {
      created: `A new task "${taskTitle}" has been created.`,
      assigned: assignedBy 
        ? `${assignedBy} assigned you the task "${taskTitle}".`
        : `You've been assigned the task "${taskTitle}".`,
      updated: `The task "${taskTitle}" has been updated.`,
      completed: `The task "${taskTitle}" has been marked as completed.`,
      dueToday: `The task "${taskTitle}" is due today.`,
      overdue: `The task "${taskTitle}" is overdue.`
    };

    const priority = action === 'overdue' ? 'critical' : 
                     action === 'dueToday' ? 'high' : 
                     action === 'assigned' ? 'high' : 'medium';

    return await Notification.create({
      owner: userId,
      title: titles[action] || `Task: ${taskTitle}`,
      message: messages[action] || `Update for task "${taskTitle}".`,
      type: 'tasks',
      priority,
      taskId,
      metadata: { dueDate, assignedBy }
    });
  }

  /**
   * Create a procurement notification
   */
  static async createProcurementNotification(userId, { itemName, procurementId, action, deliveryDate, supplier }) {
    const titles = {
      ordered: `Procurement Order: ${itemName}`,
      shipped: `Item Shipped: ${itemName}`,
      delivered: `Item Delivered: ${itemName}`,
      delayed: `Delivery Delayed: ${itemName}`,
      cancelled: `Order Cancelled: ${itemName}`
    };

    const messages = {
      ordered: `A procurement order for "${itemName}" has been placed.`,
      shipped: `The item "${itemName}" has been shipped${supplier ? ` by ${supplier}` : ''}.`,
      delivered: `The item "${itemName}" has been delivered.`,
      delayed: `The delivery of "${itemName}" has been delayed${deliveryDate ? ` to ${deliveryDate}` : ''}.`,
      cancelled: `The procurement order for "${itemName}" has been cancelled.`
    };

    const priority = action === 'delayed' ? 'high' : 
                     action === 'cancelled' ? 'high' : 'medium';

    return await Notification.create({
      owner: userId,
      title: titles[action] || `Procurement: ${itemName}`,
      message: messages[action] || `Update for procurement item "${itemName}".`,
      type: 'procurement',
      priority,
      procurementId,
      metadata: { deliveryDate, supplier }
    });
  }

  /**
   * Create a meeting notification
   */
  static async createMeetingNotification(userId, { meetingTitle, meetingId, action, startTime, location, organizer }) {
    const titles = {
      scheduled: `Meeting Scheduled: ${meetingTitle}`,
      updated: `Meeting Updated: ${meetingTitle}`,
      cancelled: `Meeting Cancelled: ${meetingTitle}`,
      reminder: `Meeting Reminder: ${meetingTitle}`,
      started: `Meeting Started: ${meetingTitle}`
    };

    const messages = {
      scheduled: `A meeting "${meetingTitle}" has been scheduled${startTime ? ` for ${startTime}` : ''}${location ? ` at ${location}` : ''}.`,
      updated: `The meeting "${meetingTitle}" details have been updated.`,
      cancelled: `The meeting "${meetingTitle}" has been cancelled.`,
      reminder: `Reminder: Your meeting "${meetingTitle}" is starting soon${startTime ? ` at ${startTime}` : ''}.`,
      started: `The meeting "${meetingTitle}" has started.`
    };

    const priority = action === 'reminder' ? 'high' : 
                     action === 'cancelled' ? 'high' : 'medium';

    return await Notification.create({
      owner: userId,
      title: titles[action] || `Meeting: ${meetingTitle}`,
      message: messages[action] || `Update for meeting "${meetingTitle}".`,
      type: 'meetings',
      priority,
      meetingId,
      metadata: { startTime, location, organizer }
    });
  }

  /**
   * Create a note notification
   */
  static async createNoteNotification(userId, { noteTitle, noteId, action, tag }) {
    const titles = {
      created: `New Note: ${noteTitle}`,
      updated: `Note Updated: ${noteTitle}`,
      deleted: `Note Deleted: ${noteTitle}`
    };

    const messages = {
      created: `A new note "${noteTitle}" has been created${tag ? ` with tag "${tag}"` : ''}.`,
      updated: `The note "${noteTitle}" has been updated.`,
      deleted: `The note "${noteTitle}" has been deleted.`
    };

    return await Notification.create({
      owner: userId,
      title: titles[action] || `Note: ${noteTitle}`,
      message: messages[action] || `Update for note "${noteTitle}".`,
      type: 'notes',
      priority: 'low',
      noteId,
      metadata: { tag }
    });
  }

  /**
   * Create a communication notification
   */
  static async createCommunicationNotification(userId, { senderName, chatId, messagePreview, action = 'received' }) {
    const titles = {
      received: `New Message from ${senderName}`,
      mention: `${senderName} mentioned you`,
      missed: `Missed messages from ${senderName}`
    };

    const messages = {
      received: messagePreview
        ? `${senderName}: "${messagePreview.substring(0, 100)}${messagePreview.length > 100 ? '...' : ''}"`
        : `You have a new message from ${senderName}.`,
      mention: `${senderName} mentioned you in a conversation.`,
      missed: `You have missed messages from ${senderName}.`
    };

    return await Notification.create({
      owner: userId,
      title: titles[action] || `Message from ${senderName}`,
      message: messages[action] || `New message from ${senderName}.`,
      type: 'communication',
      priority: action === 'mention' ? 'high' : 'medium',
      metadata: { chatId, senderName }
    });
  }

  /**
   * Create a general notification
   */
  static async createGeneralNotification(userId, { title, message, priority = 'medium', metadata }) {
    return await Notification.create({
      owner: userId,
      title,
      message,
      type: 'general',
      priority,
      metadata
    });
  }

  /**
   * Bulk create notifications for multiple users
   */
  static async createBulkNotifications(userIds, notificationData) {
    const notifications = userIds.map(userId => ({
      owner: userId,
      ...notificationData
    }));

    return await Notification.insertMany(notifications);
  }

  /**
   * Delete old read notifications (cleanup)
   */
  static async cleanupOldNotifications(daysOld = 30) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysOld);

    const result = await Notification.deleteMany({
      isRead: true,
      createdAt: { $lt: cutoffDate }
    });

    return result.deletedCount;
  }
}

export default NotificationService;
