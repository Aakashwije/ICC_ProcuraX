import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:procurax_frontend/services/api_service.dart' as core_api;

class ApiService {
  static String get baseUrl => '${core_api.ApiService.baseUrl}/api';

  static const Duration _timeout = Duration(seconds: 8);

  /// Fetch settings from MongoDB backend
  static Future<Map<String, dynamic>> getSettings() async {
    try {
      final url = Uri.parse('$baseUrl/settings');
      if (kDebugMode) {
        debugPrint('📡 Fetching settings from: $url');
      }

      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          return data['data'] ?? {};
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error in getSettings: $e');
      }
    }

    // Return default settings if anything fails
    return {
      'theme': 'Light',
      'timezone': 'UTC',
      'role': 'Project Manager',
      'department': 'Construction',
      'defaultProject': 'Tower A - Downtown',
    };
  }

  /// Update settings in MongoDB
  static Future<void> updateMultipleSettings(
    Map<String, dynamic> settings,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/settings/bulk');
      if (kDebugMode) {
        debugPrint('📡 Updating settings at: $url');
      }

      final response = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(settings),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ Settings saved to MongoDB');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error saving settings: $e');
      }
    }
  }
}
