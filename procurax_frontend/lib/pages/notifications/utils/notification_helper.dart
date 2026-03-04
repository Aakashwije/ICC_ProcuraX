import 'package:provider/provider.dart';
import 'package:procurax_frontend/main.dart' show navigatorKey;
import '../models/alert_model.dart';
import '../providers/alert_provider.dart';

/// NotificationHelper - Centralized hub for creating notifications from anywhere in the app
///
/// This class provides static methods to create notifications from anywhere in the app.
/// Other modules (Tasks, Meetings, Procurement, Projects) can use these methods to
/// trigger notifications that will appear in the Notifications page.
///
/// Usage Examples:
/// 1. From Tasks module when a task is created:
///    NotificationHelper.taskCreated(taskId: '123', taskTitle: 'New Task');
///
/// 2. From Meetings module when a meeting is scheduled:
///    NotificationHelper.meetingScheduled(meetingId: '456', meetingTitle: 'Team Meeting', startTime: DateTime.now());
///
/// 3. From Procurement module when an order is placed:
///    NotificationHelper.procurementUpdate(procurementId: '789', message: 'Order #789 placed successfully');
class NotificationHelper {
  /// Get the AlertProvider instance
  static AlertProvider? _getProvider() {
    final context = navigatorKey.currentContext;
    if (context == null) return null;
    return Provider.of<AlertProvider>(context, listen: false);
  }

  // ==================== TASK NOTIFICATIONS ====================

  /// Task created notification
  static Future<void> taskCreated({
    required String taskId,
    required String taskTitle,
  }) async {
    await _createNotification(
      title: 'New Task Created',
      message: 'Task "$taskTitle" has been created',
      type: AlertType.tasks,
      priority: AlertPriority.medium,
      taskId: taskId,
    );
  }

  /// Task assigned notification
  static Future<void> taskAssigned({
    required String taskId,
    required String taskTitle,
    String? assignedBy,
  }) async {
    await _createNotification(
      title: 'Task Assigned',
      message: assignedBy != null
          ? '$assignedBy assigned you task "$taskTitle"'
          : 'You have been assigned task "$taskTitle"',
      type: AlertType.tasks,
      priority: AlertPriority.high,
      taskId: taskId,
    );
  }

  /// Task completed notification
  static Future<void> taskCompleted({
    required String taskId,
    required String taskTitle,
  }) async {
    await _createNotification(
      title: 'Task Completed',
      message: 'Task "$taskTitle" has been marked as completed',
      type: AlertType.tasks,
      priority: AlertPriority.low,
      taskId: taskId,
    );
  }

  /// Task due soon notification
  static Future<void> taskDueSoon({
    required String taskId,
    required String taskTitle,
    required DateTime dueDate,
  }) async {
    await _createNotification(
      title: 'Task Due Soon',
      message: 'Task "$taskTitle" is due soon',
      type: AlertType.tasks,
      priority: AlertPriority.high,
      taskId: taskId,
    );
  }

  // ==================== MEETING NOTIFICATIONS ====================

  /// Meeting scheduled notification
  static Future<void> meetingScheduled({
    required String meetingId,
    required String meetingTitle,
    required DateTime startTime,
  }) async {
    await _createNotification(
      title: 'Meeting Scheduled',
      message: 'Meeting "$meetingTitle" scheduled for ${_formatDateTime(startTime)}',
      type: AlertType.meetings,
      priority: AlertPriority.medium,
      meetingId: meetingId,
    );
  }

  /// Meeting reminder notification
  static Future<void> meetingReminder({
    required String meetingId,
    required String meetingTitle,
    required DateTime startTime,
    int minutesBefore = 15,
  }) async {
    await _createNotification(
      title: 'Meeting Reminder',
      message: 'Meeting "$meetingTitle" starts in $minutesBefore minutes',
      type: AlertType.meetings,
      priority: AlertPriority.critical,
      meetingId: meetingId,
    );
  }

  /// Meeting cancelled notification
  static Future<void> meetingCancelled({
    required String meetingId,
    required String meetingTitle,
  }) async {
    await _createNotification(
      title: 'Meeting Cancelled',
      message: 'Meeting "$meetingTitle" has been cancelled',
      type: AlertType.meetings,
      priority: AlertPriority.high,
      meetingId: meetingId,
    );
  }

  /// Meeting updated notification
  static Future<void> meetingUpdated({
    required String meetingId,
    required String meetingTitle,
  }) async {
    await _createNotification(
      title: 'Meeting Updated',
      message: 'Meeting "$meetingTitle" details have been updated',
      type: AlertType.meetings,
      priority: AlertPriority.medium,
      meetingId: meetingId,
    );
  }

  // ==================== PROJECT NOTIFICATIONS ====================

  /// Project assigned notification
  static Future<void> projectAssigned({
    required String projectId,
    required String projectName,
  }) async {
    await _createNotification(
      title: 'New Project Assigned',
      message: 'You have been assigned to project "$projectName"',
      type: AlertType.projects,
      priority: AlertPriority.high,
      projectId: projectId,
      projectName: projectName,
      projectStatus: 'assigned',
    );
  }

  /// Project status changed notification
  static Future<void> projectStatusChanged({
    required String projectId,
    required String projectName,
    required String newStatus,
  }) async {
    await _createNotification(
      title: 'Project Status Changed',
      message: 'Project "$projectName" status changed to $newStatus',
      type: AlertType.projects,
      priority: AlertPriority.medium,
      projectId: projectId,
      projectName: projectName,
      projectStatus: newStatus,
    );
  }

  /// Project deadline approaching notification
  static Future<void> projectDeadlineApproaching({
    required String projectId,
    required String projectName,
    required DateTime deadline,
  }) async {
    await _createNotification(
      title: 'Project Deadline Approaching',
      message: 'Project "$projectName" deadline is ${_formatDateTime(deadline)}',
      type: AlertType.projects,
      priority: AlertPriority.high,
      projectId: projectId,
      projectName: projectName,
    );
  }

  // ==================== PROCUREMENT NOTIFICATIONS ====================
  
  /// Procurement order created notification
  static Future<void> procurementOrderCreated({
    required String procurementId,
    required String orderDetails,
  }) async {
    await _createNotification(
      title: 'Procurement Order Created',
      message: 'Order $orderDetails has been created',
      type: AlertType.procurement,
      priority: AlertPriority.medium,
      procurementId: procurementId,
    );
  }

  /// Procurement update notification
  static Future<void> procurementUpdate({
    required String procurementId,
    required String message,
  }) async {
    await _createNotification(
      title: 'Procurement Update',
      message: message,
      type: AlertType.procurement,
      priority: AlertPriority.medium,
      procurementId: procurementId,
    );
  }

  /// Procurement approved notification
  static Future<void> procurementApproved({
    required String procurementId,
    required String orderDetails,
  }) async {
    await _createNotification(
      title: 'Procurement Approved',
      message: 'Order $orderDetails has been approved',
      type: AlertType.procurement,
      priority: AlertPriority.high,
      procurementId: procurementId,
    );
  }

  /// Procurement delivered notification
  static Future<void> procurementDelivered({
    required String procurementId,
    required String orderDetails,
  }) async {
    await _createNotification(
      title: 'Procurement Delivered',
      message: 'Order $orderDetails has been delivered',
      type: AlertType.procurement,
      priority: AlertPriority.low,
      procurementId: procurementId,
    );
  }

  // ==================== GENERAL NOTIFICATIONS ====================
  
  /// Custom general notification
  static Future<void> general({
    required String title,
    required String message,
    AlertPriority priority = AlertPriority.medium,
  }) async {
    await _createNotification(
      title: title,
      message: message,
      type: AlertType.general,
      priority: priority,
    );
  }

  // ==================== INTERNAL HELPERS ====================
  
  /// Internal method to create notification
  static Future<void> _createNotification({
    required String title,
    required String message,
    required AlertType type,
    required AlertPriority priority,
    String? projectId,
    String? projectName,
    String? projectStatus,
    String? taskId,
    String? meetingId,
    String? procurementId,
  }) async {
    final provider = _getProvider();
    if (provider == null) {
      print('Warning: Could not get AlertProvider. Notification not created.');
      return;
    }

    await provider.createNotification(
      title: title,
      message: message,
      type: type,
      priority: priority,
      projectId: projectId,
      projectName: projectName,
      projectStatus: projectStatus,
      taskId: taskId,
      meetingId: meetingId,
      procurementId: procurementId,
    );
  }

  /// Format DateTime for display
  static String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateToCheck == today) {
      return 'today at ${_formatTime(dateTime)}';
    } else if (dateToCheck == today.add(const Duration(days: 1))) {
      return 'tomorrow at ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${_formatTime(dateTime)}';
    }
  }

  /// Format time for display
  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
