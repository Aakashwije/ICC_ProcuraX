import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiService {
  // Update this base URL if the backend host changes.
  static String get baseUrl {
    const override = String.fromEnvironment("API_BASE_URL");
    if (override.isNotEmpty) {
      return override;
    }
    if (kIsWeb) {
      return "http://localhost:3000";
    }
    if (Platform.isAndroid) {
      return "http://10.0.2.2:3000"; // Android emulator -> host machine
    }
    return "http://localhost:3000"; // iOS simulator / desktop
  }

  // TODO: Replace with a secure storage/token flow for production.
  static const String appToken = "procura_app_9f3a7c2d";

  static Map<String, String> get authHeaders => {
    "Authorization": "Bearer $appToken",
    "Content-Type": "application/json",
  };
}
