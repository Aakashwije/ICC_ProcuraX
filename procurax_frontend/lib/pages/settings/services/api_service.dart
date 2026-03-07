import 'dart:io';
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
      rethrow;
    }
  }

  /// Upload profile image to backend
  static Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    try {
      final url = Uri.parse('$baseUrl/users/profile-image');

      if (kDebugMode) {
        debugPrint('📡 Uploading profile image to: $url');
      }

      // Create multipart request
      var request = http.MultipartRequest('POST', url);

      // Add file to request
      request.files.add(
        await http.MultipartFile.fromPath(
          'profileImage',
          imageFile.path,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      // Send request
      var streamedResponse = await request.send().timeout(_timeout);
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          debugPrint('✅ Profile image uploaded successfully');
        }
        return data;
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to upload image: ${response.statusCode}');
        }
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error uploading image: $e');
      }
      rethrow;
    }
  }

  /// Remove profile image
  static Future<void> removeProfileImage() async {
    try {
      final url = Uri.parse('$baseUrl/users/profile-image');

      if (kDebugMode) {
        debugPrint('📡 Removing profile image from: $url');
      }

      final response = await http.delete(url).timeout(_timeout);

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('✅ Profile image removed successfully');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to remove image: ${response.statusCode}');
        }
        throw Exception('Failed to remove image: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error removing image: $e');
      }
      rethrow;
    }
  }

  /// Get user profile including image URL
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final url = Uri.parse('$baseUrl/users/me');

      if (kDebugMode) {
        debugPrint('📡 Fetching user profile from: $url');
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
        debugPrint('⚠️ Error fetching user profile: $e');
      }
    }
    return {};
  }
}
