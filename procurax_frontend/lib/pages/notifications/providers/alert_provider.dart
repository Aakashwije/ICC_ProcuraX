import 'package:flutter/material.dart';
import 'package:procurax_frontend/services/api_service.dart';
import '../models/alert_model.dart';
import '../services/notification_api_service.dart';

class AlertProvider extends ChangeNotifier {
  final List<AlertModel> _alerts = [];
  bool _isLoading = false;
  String? _error;

  List<AlertModel> get alerts => List.unmodifiable(_alerts);
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _alerts.where((a) => !a.isRead).length;

  /// Initialize by fetching notifications from backend
  Future<void> initialize() async {
    if (!ApiService.hasToken) return;
    await fetchNotifications();
  }

  /// Fetch notifications from the backend
  Future<void> fetchNotifications({
    String? type,
    String? priority,
    bool? isRead,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('[AlertProvider] Fetching notifications...');
      debugPrint('[AlertProvider] Token present: ${ApiService.hasToken}');
      debugPrint('[AlertProvider] Base URL: ${ApiService.baseUrl}');

      final notifications = await NotificationApiService.fetchNotifications(
        type: type,
        priority: priority,
        isRead: isRead,
      );

      debugPrint(
        '[AlertProvider] Fetched ${notifications.length} notifications',
      );

      _alerts.clear();
      _alerts.addAll(notifications);
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('[AlertProvider] Error fetching notifications: $e');
      debugPrint('[AlertProvider] Stack trace: $stackTrace');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(AlertModel alert) async {
    try {
      await NotificationApiService.markAsRead(alert.id);

      // Update local state
      final index = _alerts.indexWhere((a) => a.id == alert.id);
      if (index != -1) {
        _alerts[index] = _alerts[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead({String? type}) async {
    try {
      await NotificationApiService.markAllAsRead(type: type);

      // Update local state
      for (int i = 0; i < _alerts.length; i++) {
        if (type == null || _alerts[i].type.name == type) {
          _alerts[i] = _alerts[i].copyWith(isRead: true);
        }
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete a notification
  Future<void> deleteAlert(AlertModel alert) async {
    try {
      await NotificationApiService.deleteNotification(alert.id);

      // Update local state
      _alerts.removeWhere((a) => a.id == alert.id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Add a new notification (e.g., for real-time updates)
  void addAlert(AlertModel alert) {
    _alerts.insert(0, alert);
    notifyListeners();
  }

  /// Create a new notification via API
  Future<void> createNotification({
    required String title,
    required String message,
    required AlertType type,
    required AlertPriority priority,
    String? projectName,
    String? projectStatus,
    String? projectId,
    String? taskId,
    String? meetingId,
    String? procurementId,
    Map<String, dynamic>? metadata,
    String? actionUrl,
  }) async {
    try {
      final notification = await NotificationApiService.createNotification(
        title: title,
        message: message,
        type: type,
        priority: priority,
        projectName: projectName,
        projectStatus: projectStatus,
        projectId: projectId,
        taskId: taskId,
        meetingId: meetingId,
        procurementId: procurementId,
        metadata: metadata,
        actionUrl: actionUrl,
      );

      _alerts.insert(0, notification);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Refresh notifications
  Future<void> refresh() async {
    await fetchNotifications();
  }
}
