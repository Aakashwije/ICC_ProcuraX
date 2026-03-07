import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:procurax_frontend/services/api_service.dart';
import 'package:procurax_frontend/services/firebase_service.dart';

class AuthService {
  static String get _loginEndpoint => "${ApiService.baseUrl}/auth/login";
  static String get _registerEndpoint => "${ApiService.baseUrl}/auth/register";
  static String get _forgotPasswordEndpoint =>
      "${ApiService.baseUrl}/auth/forgot-password";
  static String get _verifyOtpEndpoint =>
      "${ApiService.baseUrl}/auth/verify-otp";
  static String get _resetPasswordEndpoint =>
      "${ApiService.baseUrl}/auth/reset-password";

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
      final userData = body["user"] as Map<String, dynamic>?;

      if (token == null || token.isEmpty) {
        throw Exception("Login succeeded but token missing");
      }
      await ApiService.setAuthToken(token, persist: rememberMe);

      // Save the logged in user's ID locally so the communication
      // page knows which user is authenticated across the app.
      if (userData != null && userData["id"] != null) {
        await ApiService.setUserId(
          userData["id"].toString(),
          persist: rememberMe,
        );
      }

      // Sync the user to Firestore after a successful login
      if (userData != null && userData["id"] != null) {
        await FirebaseService.syncUserOnLogin(
          userData["id"].toString(),
          userData,
        );
      }

      return;
    }

    // Handle authentication / approval errors
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final message = body["message"] ?? body["error"] ?? "Login failed";

      // If we got a 403 and 'approved' is false, it's the approval gate
      if (response.statusCode == 403 && body["approved"] == false) {
        throw Exception(message.toString());
      }

      throw Exception(message.toString());
    } catch (e) {
      if (e is FormatException) {
        throw Exception("Login failed (${response.statusCode})");
      }
      rethrow;
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

  /// Request a password-reset OTP to be sent to the given email.
  /// Returns a map with `expiresIn` (minutes) on success.
  Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    final response = await http
        .post(
          Uri.parse(_forgotPasswordEndpoint),
          headers: const {"Content-Type": "application/json"},
          body: jsonEncode({"email": email.trim()}),
        )
        .timeout(const Duration(seconds: 15));

    final body = _parseBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw PasswordResetException.fromResponse(response.statusCode, body);
  }

  /// Verify the OTP code for password reset.
  /// Returns a map with `attemptsRemaining` if the code is wrong.
  Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otp,
  }) async {
    final response = await http
        .post(
          Uri.parse(_verifyOtpEndpoint),
          headers: const {"Content-Type": "application/json"},
          body: jsonEncode({"email": email.trim(), "otp": otp.trim()}),
        )
        .timeout(const Duration(seconds: 15));

    final body = _parseBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw PasswordResetException.fromResponse(response.statusCode, body);
  }

  /// Reset the password using the OTP and a new password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await http
        .post(
          Uri.parse(_resetPasswordEndpoint),
          headers: const {"Content-Type": "application/json"},
          body: jsonEncode({
            "email": email.trim(),
            "otp": otp.trim(),
            "newPassword": newPassword,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final body = _parseBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw PasswordResetException.fromResponse(response.statusCode, body);
  }

  /// Safely parse response body, returning empty map on failure
  Map<String, dynamic> _parseBody(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {"message": "Unexpected server response"};
    }
  }
}

/// Structured exception for password reset errors with error codes
class PasswordResetException implements Exception {
  final String code;
  final String message;
  final int statusCode;
  final int? attemptsRemaining;
  final int? retryAfter;
  final List<String>? requirements;

  PasswordResetException({
    required this.code,
    required this.message,
    required this.statusCode,
    this.attemptsRemaining,
    this.retryAfter,
    this.requirements,
  });

  factory PasswordResetException.fromResponse(
    int statusCode,
    Map<String, dynamic> body,
  ) {
    return PasswordResetException(
      code: (body["code"] as String?) ?? "UNKNOWN",
      message: (body["message"] as String?) ?? "Something went wrong",
      statusCode: statusCode,
      attemptsRemaining: body["attemptsRemaining"] as int?,
      retryAfter: body["retryAfter"] as int?,
      requirements: (body["requirements"] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  bool get isLocked => code == "ACCOUNT_LOCKED";
  bool get isRateLimited => code == "RATE_LIMITED";
  bool get isExpired => code == "OTP_EXPIRED";
  bool get isInvalidOTP => code == "INVALID_OTP";
  bool get isWeakPassword => code == "WEAK_PASSWORD";
  bool get isSamePassword => code == "SAME_PASSWORD";

  @override
  String toString() => message;
}
