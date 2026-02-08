import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Now using port 3000
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  /// Fetch settings from MongoDB backend
  static Future<Map<String, dynamic>> getSettings() async {
    try {
      final url = Uri.parse('$baseUrl/settings');
      print('📡 Fetching settings from: $url');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          return data['data'] ?? {};
        }
      }
    } catch (e) {
      print('⚠️ Error in getSettings: $e');
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
      print('📡 Updating settings at: $url');

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(settings),
      );

      if (response.statusCode == 200) {
        print('✅ Settings saved to MongoDB');
      }
    } catch (e) {
      print('⚠️ Error saving settings: $e');
    }
  }
}
