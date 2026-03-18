import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:procurax_frontend/services/api_service.dart' as core_api;

class ApiService {
  static String get baseUrl => '${core_api.ApiService.baseUrl}/api';
  static const Duration _timeout = Duration(seconds: 8);
  static const Duration _uploadTimeout = Duration(seconds: 30);

  static bool hasToken() {
    return _authToken != null && _authToken!.isNotEmpty;
  }

  // Token management
  static String? _authToken;

  // Call this after login to store the token
  static Future<void> setAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Call this at app startup to load the token
  static Future<void> loadAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
    } catch (e) {
      // ignore
    }
  }

  // Clear token on logout
  static Future<void> clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Get headers with auth token
  static Future<void> _ensureTokenLoaded() async {
    if (_authToken == null || _authToken!.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
    }
  }

  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_authToken != null && _authToken!.isNotEmpty)
        'Authorization': 'Bearer $_authToken',
    };
  }

  /// Fetch settings from MongoDB backend
  static Future<Map<String, dynamic>> getSettings() async {
    try {
      await _ensureTokenLoaded();
      final url = Uri.parse('$baseUrl/settings');
      final response = await http
          .get(url, headers: _getHeaders())
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          return data['data'] ?? {};
        }
      }
    } catch (e) {
      // ignore, return defaults below
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
      await _ensureTokenLoaded();
      final url = Uri.parse('$baseUrl/settings/bulk');
      final response = await http
          .put(url, headers: _getHeaders(), body: jsonEncode(settings))
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to save settings: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Upload profile image to backend
  static Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    try {
      await _ensureTokenLoaded();
      final url = Uri.parse('$baseUrl/upload/profile-image');

      // Create multipart request
      var request = http.MultipartRequest('POST', url);

      // Add auth token to headers
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      // Add file to request
      request.files.add(
        await http.MultipartFile.fromPath(
          'profileImage',
          imageFile.path,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      // Send request (uploads can take longer than normal API calls)
      var streamedResponse = await request.send().timeout(_uploadTimeout);
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic>
            ? decoded
            : <String, dynamic>{};
        return data;
      } else {
        String backendMessage = 'Failed to upload image';
        try {
          final dynamic decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            final msg = decoded['message'] ?? decoded['error'];
            if (msg is String && msg.isNotEmpty) {
              backendMessage = msg;
            }
          }
        } catch (_) {
          // Keep fallback message when response is not JSON.
        }
        throw Exception('$backendMessage (${response.statusCode})');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Remove profile image
  static Future<void> removeProfileImage() async {
    try {
      await _ensureTokenLoaded();
      final url = Uri.parse('$baseUrl/upload/profile-image');
      final response = await http
          .delete(url, headers: _getHeaders())
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to remove image: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get user profile including image URL
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      await _ensureTokenLoaded();
      final url = Uri.parse('$baseUrl/users/me');
      final response = await http
          .get(url, headers: _getHeaders())
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] ?? {};
        }
      }
    } catch (e) {
      // ignore
    }
    return {};
  }

  /// Update user profile information (WORKS WITH AUTO-SAVE)
  static Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      await _ensureTokenLoaded();
      // This endpoint matches your user.routes.js /profile endpoint
      final url = Uri.parse('$baseUrl/users/profile');
      final response = await http
          .put(url, headers: _getHeaders(), body: jsonEncode(profileData))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data;
        }
      }

      throw Exception('Failed to update profile: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }
}
