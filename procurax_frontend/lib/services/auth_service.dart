import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:procurax_frontend/services/api_service.dart';

class AuthService {
  static String get _loginEndpoint => "${ApiService.baseUrl}/auth/login";
  static String get _registerEndpoint => "${ApiService.baseUrl}/auth/register";

  Future<void> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    final response = await http.post(
      Uri.parse(_loginEndpoint),
      headers: const {"Content-Type": "application/json"},
      body: jsonEncode({"email": email.trim(), "password": password}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final token = body["token"] as String?;
      if (token == null || token.isEmpty) {
        throw Exception("Login succeeded but token missing");
      }
      await ApiService.setAuthToken(token, persist: rememberMe);
      return;
    }

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message = body["message"] ?? body["error"] ?? "Login failed";
      throw Exception(message.toString());
    } catch (_) {
      throw Exception("Login failed (${response.statusCode})");
    }
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(_registerEndpoint),
      headers: const {"Content-Type": "application/json"},
      body: jsonEncode({"email": email.trim(), "password": password}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message = body["message"] ?? body["error"] ?? "Register failed";
      throw Exception(message.toString());
    } catch (_) {
      throw Exception("Register failed (${response.statusCode})");
    }
  }
}
