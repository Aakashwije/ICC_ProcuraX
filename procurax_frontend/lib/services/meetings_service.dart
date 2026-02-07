import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:procurax_frontend/services/api_service.dart';
import 'package:procurax_frontend/pages/meetings/features/smart_calendar/models/meeting.dart';

class MeetingsService {
  static String get _endpoint => "${ApiService.baseUrl}/api/meetings";

  static Future<List<Meeting>> fetchMeetings() async {
    try {
      final response = await http
          .get(Uri.parse(_endpoint), headers: ApiService.authHeaders)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          "Failed to load meetings (status ${response.statusCode})",
        );
      }

      final List<dynamic> data = json.decode(response.body) as List<dynamic>;
      return data
          .map((item) => Meeting.fromJson(item as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      throw Exception(
        "Request timed out. Check that the backend is running at ${ApiService.baseUrl}.",
      );
    } on http.ClientException catch (err) {
      throw Exception(
        "Network error: ${err.message}. Check the backend URL and device network.",
      );
    }
  }

  static Future<Meeting> createMeeting(Meeting meeting) async {
    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: ApiService.authHeaders,
            body: json.encode(meeting.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 201) {
        throw Exception(
          "Failed to create meeting (status ${response.statusCode})",
        );
      }

      final Map<String, dynamic> data =
          json.decode(response.body) as Map<String, dynamic>;
      return Meeting.fromJson(data);
    } on TimeoutException {
      throw Exception(
        "Request timed out. Check that the backend is running at ${ApiService.baseUrl}.",
      );
    } on http.ClientException catch (err) {
      throw Exception(
        "Network error: ${err.message}. Check the backend URL and device network.",
      );
    }
  }
}
