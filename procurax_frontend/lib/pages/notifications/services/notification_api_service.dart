import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:procurax_frontend/services/api_service.dart';
import '../models/alert_model.dart';

class NotificationApiService {
  static String get baseUrl => '${ApiService.baseUrl}/api/notifications';

  /// Fetch all notifications for the authenticated user
  static Future<List<AlertModel>> fetchNotifications({
    String? type,
    String? priority,
    bool? isRead,
  }) async {
    try {
      final token = ApiService.token;
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Build query parameters
      final queryParams = <String, String>{};
      if (type != null) queryParams['type'] = type;
      if (priority != null) queryParams['priority'] = priority;
      if (isRead != null) queryParams['isRead'] = isRead.toString();

      final uri = Uri.parse(
        baseUrl,
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      debugPrint('[NotificationApiService] Fetching from: $uri');
      debugPrint('[NotificationApiService] Headers: ${ApiService.authHeaders}');

      final response = await http.get(uri, headers: ApiService.authHeaders);

      debugPrint(
        '[NotificationApiService] Response status: ${response.statusCode}',
      );
      debugPrint('[NotificationApiService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final notifications = data['notifications'] as List;

        debugPrint(
          '[NotificationApiService] Parsed ${notifications.length} notifications',
        );

        return notifications.map((json) => AlertModel.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to fetch notifications: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      rethrow;
    }
  }

  /// Mark a notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      final token = ApiService.token;
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/$notificationId/read'),
        headers: ApiService.authHeaders,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to mark notification as read: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead({String? type}) async {
    try {
      final token = ApiService.token;
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final queryParams = <String, String>{};
      if (type != null) queryParams['type'] = type;

      final uri = Uri.parse(
        '$baseUrl/mark-all/read',
      ).replace(queryParameters: queryParams);

      final response = await http.patch(uri, headers: ApiService.authHeaders);

      if (response.statusCode != 200) {
        throw Exception('Failed to mark all as read: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      rethrow;
    }
  }

  /// Delete a notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      final token = ApiService.token;
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/$notificationId'),
        headers: ApiService.authHeaders,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to delete notification: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }

  /// Create a new notification
  static Future<AlertModel> createNotification({
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
      final token = ApiService.token;
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final body = {
        'title': title,
        'message': message,
        'type': type.name,
        'priority': priority.name,
        if (projectName != null) 'projectName': projectName,
        if (projectStatus != null) 'projectStatus': projectStatus,
        if (projectId != null) 'projectId': projectId,
        if (taskId != null) 'taskId': taskId,
        if (meetingId != null) 'meetingId': meetingId,
        if (procurementId != null) 'procurementId': procurementId,
        if (metadata != null) 'metadata': metadata,
        if (actionUrl != null) 'actionUrl': actionUrl,
      };

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: ApiService.authHeaders,
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return AlertModel.fromJson(data);
      } else {
        throw Exception(
          'Failed to create notification: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error creating notification: $e');
      rethrow;
    }
  }

  /// Get notification statistics
  static Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final token = ApiService.token;
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/stats'),
        headers: ApiService.authHeaders,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch stats: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching notification stats: $e');
      rethrow;
    }
  }
}
