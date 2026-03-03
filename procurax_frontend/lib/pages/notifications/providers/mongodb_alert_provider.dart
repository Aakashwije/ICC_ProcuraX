import 'package:flutter/material.dart';
import '../models/alert_model.dart';

class MongoDBAlertProvider extends ChangeNotifier {
  final List<AlertModel> _alerts = [];

  List<AlertModel> get alerts => List.unmodifiable(_alerts);

  int get unreadCount => _alerts.where((a) => !a.isRead).length;

  Future<void> initialize() async {
    // TODO: Replace this with actual MongoDB fetch
    await Future.delayed(const Duration(seconds: 1));
    _alerts.addAll([
      AlertModel(
        id: '101',
        title: 'MongoDB Project Alert',
        message: 'New project synced from MongoDB.',
        type: AlertType.projects,
        priority: AlertPriority.medium,
        isRead: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ]);
    notifyListeners();
  }

  Future<void> markAsRead(AlertModel alert) async {
    final index = _alerts.indexWhere((a) => a.id == alert.id);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  Future<void> deleteAlert(AlertModel alert) async {
    _alerts.removeWhere((a) => a.id == alert.id);
    notifyListeners();
  }

  Future<void> addAlert(AlertModel alert) async {
    _alerts.insert(0, alert);
    notifyListeners();
  }
}
