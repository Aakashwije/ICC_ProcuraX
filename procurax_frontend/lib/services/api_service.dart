import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Update this base URL if the backend host changes.
  static String get baseUrl {
    const override = String.fromEnvironment("API_BASE_URL");
    if (override.isNotEmpty) {
      return override;
    }
    if (kIsWeb) {
      return "http://localhost:5002"; // Web development -> backend proxy
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

  static Future<String> getToken() async {
    return _token!;
  }

  static Future<Map<String, dynamic>> getDocuments() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/documents'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  static Future<void> uploadDocument(File file, String category) async {
    final token = await getToken();
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/documents/upload'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['category'] = category;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    var response = await request.send();
    if (response.statusCode != 201) {
      throw Exception('Failed to upload document');
    }
  }

  static Future<void> deleteDocument(String documentId) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/documents/$documentId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete document');
    }
  }
}
