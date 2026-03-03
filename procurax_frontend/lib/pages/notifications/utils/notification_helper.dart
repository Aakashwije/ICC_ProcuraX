import '../models/alert_model.dart';
import '../providers/alert_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationHelper {
  static Future<void> custom({
    required String title,
    required String message,
    required AlertType type,
    required AlertPriority priority,
    Map<String, dynamic>? metadata,
    String? actionUrl,
  }) async {
    final alert = AlertModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      priority: priority,
      timestamp: DateTime.now(),
    );

    // Add alert to provider
    // NOTE: Use navigatorKey or context from your main app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Assuming a global context or navigator key
      // Replace with actual context
      final context = navigatorKey.currentContext;
      if (context != null) {
        final provider = Provider.of<AlertProvider>(context, listen: false);
        provider.addAlert(alert);
      }
    });
  }
}

// Add this in main.dart:
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
