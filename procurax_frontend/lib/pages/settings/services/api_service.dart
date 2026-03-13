import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:procurax_frontend/services/api_service.dart' as core_api;

class ApiService {
  static String get baseUrl => '${core_api.ApiService.baseUrl}/api';
  static const Duration _timeout = Duration(seconds: 8);

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
    if (kDebugMode) {
      debugPrint('Auth token saved');
    }
  }

  // Call this at app startup to load the token
  static Future<void> loadAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
      if (kDebugMode) {
        debugPrint('Auth token loaded: ${_authToken != null}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading auth token: $e');
      }
    }
  }

  // Clear token on logout
  static Future<void> clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    if (kDebugMode) {
      debugPrint('Auth token cleared');
    }
  }

  // Get headers with auth token
  static Future<void> _ensureTokenLoaded() async {
    if (_authToken == null || _authToken!.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
      if (kDebugMode) {
        debugPrint('Settings API token loaded: ${_authToken != null}');
      }
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
      if (kDebugMode) {
        debugPrint('Fetching settings from: $url');
      }

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
      if (kDebugMode) {
        debugPrint('Error in getSettings: $e');
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
      await _ensureTokenLoaded();
      final url = Uri.parse('$baseUrl/settings/bulk');
      if (kDebugMode) {
        debugPrint('Updating settings at: $url');
      }

      final response = await http
          .put(url, headers: _getHeaders(), body: jsonEncode(settings))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('Settings saved to MongoDB');
        }
      } else {
        throw Exception('Failed to save settings: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving settings: $e');
      }
      rethrow;
    }
  }

  /// Upload profile image to backend
  static Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    try {
      await _ensureTokenLoaded();
      final url = Uri.parse('$baseUrl/upload/profile-image');

      if (kDebugMode) {
        debugPrint('Uploading profile image to: $url');
        debugPrint('Token present: ${_authToken != null}');
      }

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

      // Send request
      var streamedResponse = await request.send().timeout(_timeout);
      var response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) {
        debugPrint('Response status: ${response.statusCode}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          debugPrint('Profile image uploaded successfully');
        }
        return data;
      } else {
        if (kDebugMode) {
          debugPrint('Failed to upload image: ${response.statusCode}');
          debugPrint('Response: ${response.body}');
        }
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error uploading image: $e');
      }
      rethrow;
    }
  }

  /// Remove profile image
  static Future<void> removeProfileImage() async {
    try {
      await _ensureTokenLoaded();
      final url = Uri.parse('$baseUrl/upload/profile-image');

      if (kDebugMode) {
        debugPrint('Removing profile image from: $url');
        debugPrint('Token present: ${_authToken != null}');
      }

      final response = await http
          .delete(url, headers: _getHeaders())
          .timeout(_timeout);

      if (kDebugMode) {
        debugPrint('Response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint('Profile image removed successfully');
        }
      } else {
        if (kDebugMode) {
          debugPrint('Failed to remove image: ${response.statusCode}');
        }
        throw Exception('Failed to remove image: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error removing image: $e');
      }
      rethrow;
    }
  }

  /// Get user profile including image URL
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      await _ensureTokenLoaded();
      final url = Uri.parse('$baseUrl/users/me');

      if (kDebugMode) {
        debugPrint('Fetching user profile from: $url');
        debugPrint('Token present: ${_authToken != null}');
      }

      final response = await http
          .get(url, headers: _getHeaders())
          .timeout(_timeout);

      if (kDebugMode) {
        debugPrint('Response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (kDebugMode) {
            debugPrint('User profile fetched successfully');
          }
          return data['data'] ?? {};
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching user profile: $e');
      }
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

      if (kDebugMode) {
        debugPrint('Updating user profile at: $url');
        debugPrint('Data: $profileData');
        debugPrint('Token present: ${_authToken != null}');
      }

      final response = await http
          .put(url, headers: _getHeaders(), body: jsonEncode(profileData))
          .timeout(_timeout);

      if (kDebugMode) {
        debugPrint('Response status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (kDebugMode) {
            debugPrint('User profile updated successfully');
          }
          return data;
        }
      }

      throw Exception('Failed to update profile: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating user profile: $e');
      }
      rethrow;
    }
  }
}
