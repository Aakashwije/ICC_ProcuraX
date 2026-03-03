import 'package:flutter/material.dart';
import '../models/alert_model.dart';

class AlertProvider extends ChangeNotifier {
  final List<AlertModel> _alerts = [];

  List<AlertModel> get alerts => List.unmodifiable(_alerts);

  int get unreadCount => _alerts.where((a) => !a.isRead).length;

  void initialize() {
    // Example initial alerts
    _alerts.addAll([
      AlertModel(
        id: '1',
        title: 'New Project Assigned',
        message: 'You have been assigned a new project.',
        type: AlertType.projects,
        priority: AlertPriority.high,
        isRead: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      AlertModel(
        id: '2',
        title: 'Meeting Reminder',
        message: 'Team meeting at 3 PM.',
        type: AlertType.meetings,
        priority: AlertPriority.medium,
        isRead: false,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ]);
    notifyListeners();
  }

  void markAsRead(AlertModel alert) {
    final index = _alerts.indexWhere((a) => a.id == alert.id);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void deleteAlert(AlertModel alert) {
    _alerts.removeWhere((a) => a.id == alert.id);
    notifyListeners();
  }

  void addAlert(AlertModel alert) {
    _alerts.insert(0, alert);
    notifyListeners();
  }
}
