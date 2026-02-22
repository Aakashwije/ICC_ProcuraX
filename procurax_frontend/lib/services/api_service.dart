import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Update this base URL if the backend host changes.
  static String get baseUrl {
    const override = String.fromEnvironment("API_BASE_URL");
    if (override.isNotEmpty) {
      return override;
    }
    if (kIsWeb) {
      return "http://localhost:5002";
    }
    if (Platform.isAndroid) {
      return "http://10.0.2.2:5002"; // Android emulator -> host machine
    }
    return "http://localhost:5002"; // iOS simulator / desktop
  }

  // TODO: Replace with a secure storage/token flow for production.
  static const String appToken = "procura_app_9f3a7c2d";
  static const String _tokenKey = "auth_token";
  static String? _token;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  static Future<void> setAuthToken(String token, {bool persist = true}) async {
    final prefs = await SharedPreferences.getInstance();
    _token = token;
    if (persist) {
      await prefs.setString(_tokenKey, token);
    } else {
      await prefs.remove(_tokenKey);
    }
  }

  static Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = null;
    await prefs.remove(_tokenKey);
  }

  static bool get hasToken => (_token ?? "").isNotEmpty;

  static Map<String, String> get authHeaders => {
    "Authorization": "Bearer ${_token ?? appToken}",
    "Content-Type": "application/json",
  };
}
