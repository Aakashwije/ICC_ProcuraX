import 'package:provider/provider.dart';import 'package:provider/provider.dart';import 'package:provider/provider.dart';import '../models/alert_model.dart';

import 'package:flutter/material.dart';

import '../providers/alert_provider.dart';import 'package:flutter/material.dart';

import '../models/alert_model.dart';

import 'package:procurax_frontend/main.dart' show navigatorKey;import '../providers/alert_provider.dart';import 'package:flutter/material.dart';import '../providers/alert_provider.dart';



/// NotificationHelper - Create notifications from anywhere in the appimport '../models/alert_model.dart';

class NotificationHelper {

  static AlertProvider? _getProvider() {import 'package:procurax_frontend/main.dart' show navigatorKey;import '../providers/alert_provider.dart';import 'package:flutter/material.dart';

    final context = navigatorKey.currentContext;

    if (context == null) return null;

    return Provider.of<AlertProvider>(context, listen: false);

  }/// NotificationHelper - Centralized hub for creating notificationsimport '../models/alert_model.dart';import 'package:provider/provider.dart';



  /// Task notifications/// 

  static Future<void> taskCreated({

    required String taskId,/// This class provides static methods to create notifications from anywhere in the app.import 'package:procurax_frontend/main.dart' show navigatorKey;import 'package:procurax_frontend/main.dart' show navigatorKey;

    required String taskTitle,

  }) async {/// Other modules (Tasks, Meetings, Procurement, Projects) can use these methods to

    final provider = _getProvider();

    if (provider == null) return;/// trigger notifications that will appear in the Notifications page.

    await provider.createNotification(

      title: 'New Task Created',class NotificationHelper {

      message: 'Task "$taskTitle" has been created',

      type: AlertType.tasks,  /// Get the AlertProvider instance/// NotificationHelper - Centralized hub for creating notifications from anywhere in the appclass NotificationHelper {

      priority: AlertPriority.medium,

      taskId: taskId,  static AlertProvider? _getProvider() {

    );

  }    final context = navigatorKey.currentContext;///   static Future<void> custom({



  /// Meeting notifications    if (context == null) return null;

  static Future<void> meetingScheduled({

    required String meetingId,    return Provider.of<AlertProvider>(context, listen: false);/// Usage Examples:    required String title,

    required String meetingTitle,

  }) async {  }

    final provider = _getProvider();

    if (provider == null) return;///     required String message,

    await provider.createNotification(

      title = 'Meeting Scheduled',  // ==================== TASK NOTIFICATIONS ====================

      message = 'Meeting "$meetingTitle" has been scheduled',

      type = AlertType.meetings,  /// 1. From Tasks module when a task is created:    required AlertType type,

      priority = AlertPriority.medium,

      meetingId = meetingId,  /// Task created notification

    );

  }  Future<void> taskCreated({///    NotificationHelper.taskCreated(taskId: '123', taskTitle: 'New Task');    required AlertPriority priority,



  /// Project notifications    required String taskId,

  Future<void> Function({

    required String projectId,    required String taskTitle,///     Map<String, dynamic>? metadata,

    required String projectName,

  }) projectAssigned async {  }) async {

    final provider = _getProvider();

    if (provider == null) return;    await _createNotification(/// 2. From Meetings module when a meeting is scheduled:    String? actionUrl,

    await provider.createNotification(

      title: 'New Project Assigned',      title: 'New Task Created',

      message: 'You have been assigned to project "$projectName"',

      type: AlertType.projects,      message: 'Task "$taskTitle" has been created',///    NotificationHelper.meetingScheduled(meetingId: '456', meetingTitle: 'Team Meeting', startTime: DateTime.now());  }) async {

      priority: AlertPriority.high,

      projectId: projectId,      type: AlertType.tasks,

      projectName: projectName,

      projectStatus: 'assigned',      priority: AlertPriority.medium,///     final alert = AlertModel(

    );

  }      taskId: taskId,



  /// Procurement notifications    );/// 3. From Procurement module when an order is placed:      id: DateTime.now().millisecondsSinceEpoch.toString(),

  static Future<void> procurementUpdate({

    required String procurementId,  }

    required String message,

  }) async {///    NotificationHelper.procurementUpdate(procurementId: '789', message: 'Order #789 placed successfully');      title: title,

    final provider = _getProvider();

    if (provider == null) return;  /// Task assigned notification

    await provider.createNotification(

      title: 'Procurement Update',  static Future<void> taskAssigned({///      message: message,

      message: message,

      type: AlertType.procurement,    required String taskId,

      priority: AlertPriority.medium,

      procurementId: procurementId,    required String taskTitle,class NotificationHelper {      type: type,

    );

  }    String? assignedBy,



  /// General notifications  }) async {  /// Get the AlertProvider instance      priority: priority,

  static Future<void> general({

    required String title,    await _createNotification(

    String message,

    AlertPriority priority = AlertPriority.medium,      title = 'Task Assigned',  AlertProvider? Function() _getProvider {      timestamp: DateTime.now(),

  }) async {

    final provider = _getProvider();      message: assignedBy != null

    if (provider == null) return;

    await provider.createNotification(          ? '$assignedBy assigned you task "$taskTitle"'    final context = navigatorKey.currentContext;    );

      title: title,

      message: message,          : 'You have been assigned task "$taskTitle"',

      type: AlertType.general,

      priority: priority,      type: AlertType.tasks,    if (context == null) return null;

    );

  }      priority: AlertPriority.high,

}

      taskId: taskId,    return Provider.of<AlertProvider>(context, listen: false);    // Add alert to provider

    );

  }  }    // NOTE: Use navigatorKey or context from your main app



  /// Task completed notification    WidgetsBinding.instance.addPostFrameCallback((_) {

  Future<void> taskCompleted({

    required String taskId,  // ==================== TASK NOTIFICATIONS ====================      // Assuming a global context or navigator key

    required String taskTitle,

  }) async {        // Replace with actual context

    await _createNotification(

      title: 'Task Completed',  /// Task created notification      final context = navigatorKey.currentContext;

      message: 'Task "$taskTitle" has been marked as completed',

      type: AlertType.tasks,  static Future<void> taskCreated({      if (context != null) {

      priority: AlertPriority.low,

      taskId: taskId,    required String taskId,        final provider = Provider.of<AlertProvider>(context, listen: false);

    );

  }    String taskTitle,        provider.addAlert(alert);



  // ==================== MEETING NOTIFICATIONS ====================  }) async {      }

  

  /// Meeting scheduled notification    await _createNotification(    });

  Future<void> meetingScheduled({

    required String meetingId,      title = 'New Task Created',  }

    required String meetingTitle,

    required DateTime startTime,      message: 'Task "$taskTitle" has been created',}

  }) async {

    await _createNotification(      type: AlertType.tasks,

      title: 'Meeting Scheduled',

      message: 'Meeting "$meetingTitle" scheduled',      priority: AlertPriority.medium,// Add this in main.dart:

      type: AlertType.meetings,

      priority: AlertPriority.medium,      taskId: taskId,// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

      meetingId: meetingId,

    );    )

  }  }



  /// Meeting reminder notification  /// Task assigned notification

  Future<void> meetingReminder({  Future<void> Function({

    required String meetingId,    required String taskId,

    required String meetingTitle,    required String taskTitle,

    int minutesBefore = 15,    String? assignedBy,

  }) taskAssigned async {  }) async {

    await _createNotification(    await _createNotification(

      title: 'Meeting Reminder',      title: 'Task Assigned',

      message: 'Meeting "$meetingTitle" starts in $minutesBefore minutes',      message: assignedBy != null

      type: AlertType.meetings,          ? '$assignedBy assigned you task "$taskTitle"'

      priority: AlertPriority.critical,          : 'You have been assigned task "$taskTitle"',

      meetingId: meetingId,      type: AlertType.tasks,

    );      priority: AlertPriority.high,

  }      taskId: taskId,

    );

  // ==================== PROJECT NOTIFICATIONS ====================  }

  

  /// Project assigned notification  /// Task completed notification

  Future<void> projectAssigned({  Future<void> Function({

    required String projectId,    required String taskId,

    required String projectName,    required String taskTitle,

  }) taskCompleted async {  }) async {

    await _createNotification(    await _createNotification(

      title: 'New Project Assigned',      title: 'Task Completed',

      message: 'You have been assigned to project "$projectName"',      message: 'Task "$taskTitle" has been marked as completed',

      type: AlertType.projects,      type: AlertType.tasks,

      priority: AlertPriority.high,      priority: AlertPriority.low,

      projectId: projectId,      taskId: taskId,

      projectName: projectName,    );

      projectStatus: 'assigned',  }

    );

  }  /// Task due soon notification

  Future<void> taskDueSoon({

  /// Project status changed notification    required String taskId,

  Future<void> Function({    required String taskTitle,

    required String projectId,    required DateTime dueDate,

    required String projectName,  }) projectStatusChanged async {

    required String newStatus,    await _createNotification(

  }) async {      title: 'Task Due Soon',

    await _createNotification(      message: 'Task "$taskTitle" is due soon',

      title: 'Project Status Changed',      type: AlertType.tasks,

      message: 'Project "$projectName" status changed to $newStatus',      priority: AlertPriority.high,

      type: AlertType.projects,      taskId: taskId,

      priority: AlertPriority.medium,    );

      projectId: projectId,  }

      projectName: projectName,

      projectStatus: newStatus,  // ==================== MEETING NOTIFICATIONS ====================

    );  

  }  /// Meeting scheduled notification

  Future<void> meetingScheduled({

  // ==================== PROCUREMENT NOTIFICATIONS ====================    required String meetingId,

      required String meetingTitle,

  /// Procurement order created notification    required DateTime startTime,

  Future<void> procurementOrderCreated({  }) async {

    required String procurementId,    await _createNotification(

    required String orderDetails,      title: 'Meeting Scheduled',

  }) async {      message: 'Meeting "$meetingTitle" scheduled for ${_formatDateTime(startTime)}',

    await _createNotification(      type: AlertType.meetings,

      title: 'Procurement Order Created',      priority: AlertPriority.medium,

      message: 'Order $orderDetails has been created',      meetingId: meetingId,

      type: AlertType.procurement,    );

      priority: AlertPriority.medium,  }

      procurementId: procurementId,

    );  /// Meeting reminder notification

  }  Future<void> meetingReminder({

    required String meetingId,

  /// Procurement update notification    required String meetingTitle,

  Future<void> Function({    required DateTime startTime,

    required String procurementId,    int minutesBefore = 15,

    required String message,  }) procurementUpdate async {

  }) async {    await _createNotification(

    await _createNotification(      title: 'Meeting Reminder',

      title: 'Procurement Update',      message: 'Meeting "$meetingTitle" starts in $minutesBefore minutes',

      message: message,      type: AlertType.meetings,

      type: AlertType.procurement,      priority: AlertPriority.critical,

      priority: AlertPriority.medium,      meetingId: meetingId,

      procurementId: procurementId,    );

    );  }

  }

  /// Meeting cancelled notification

  // ==================== GENERAL NOTIFICATIONS ====================  static Future<void> meetingCancelled({

      String meetingId,

  /// Custom general notification    required String meetingTitle,

  static Future<void> general({  }) async {

    String title,    await createNotification(

    String message,      title = 'Meeting Cancelled',

    AlertPriority priority = AlertPriority.medium,      message = 'Meeting "$meetingTitle" has been cancelled',

  }) async {      type: AlertType.meetings,

    await createNotification(      priority: AlertPriority.high,

      title: title,      meetingId: meetingId,

      message: message,    );

      type: AlertType.general,  }

      priority: priority,

    )  /// Meeting updated notification

  }  Future<void> meetingUpdated({

    required String meetingId,

  // ==================== INTERNAL HELPER ====================    required String meetingTitle,

    }) async {

  /// Internal method to create notification    await _createNotification(

  Future<void> createNotification({      title: 'Meeting Updated',

    required String title,      message: 'Meeting "$meetingTitle" details have been updated',

    required String message,      type: AlertType.meetings,

    required AlertType type,      priority: AlertPriority.medium,

    required AlertPriority priority,      meetingId: meetingId,

    String? projectId,    );

    String? projectName,  }

    String? projectStatus,

    String? taskId,  // ==================== PROJECT NOTIFICATIONS ====================

    String? meetingId,  

    String? procurementId,  /// Project assigned notification

  }) async {  Future<void> projectAssigned({

    final provider = _getProvider();    required String projectId,

    if (provider == null) {    required String projectName,

      print('Warning: Could not get AlertProvider. Notification not created.');  }) async {

      return;    await _createNotification(

    }      title: 'New Project Assigned',

      message: 'You have been assigned to project "$projectName"',

    await provider.createNotification(      type: AlertType.projects,

      title: title,      priority: AlertPriority.high,

      message: message,      projectId: projectId,

      type: type,      projectName: projectName,

      priority: priority,      projectStatus: 'assigned',

      projectId: projectId,    );

      projectName: projectName,  }

      projectStatus: projectStatus,

      taskId: taskId,  /// Project status changed notification

      meetingId: meetingId,  static Future<void> projectStatusChanged({

      procurementId = procurementId,    required String projectId,

    );    required String projectName,

  }    required String newStatus,

}  }) async {

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
  Future<void> projectDeadlineApproaching({
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
  Future<void> procurementOrderCreated({
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
  Future<void> procurementUpdate({
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
  Future<void> procurementApproved({
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
  Future<void> procurementDelivered({
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
  Future<void> general({
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
  Future<void> _createNotification({
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
  String _formatDateTime(DateTime dateTime) {
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
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $PM';
  }
}
