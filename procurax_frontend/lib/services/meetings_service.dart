import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_service.dart';
import '../pages/meetings/features/smart_calendar/models/meeting.dart';

class MeetingsService {
  static const String _endpoint = '/meetings';

  /// Create meeting
  static Future<void> addMeeting(Meeting meeting) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}$_endpoint'),
      headers: ApiService.authHeaders,
      body: jsonEncode(meeting.toJson()),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create meeting');
    }
  }

  /// Update meeting
  static Future<void> updateMeeting(Meeting meeting) async {
    if (meeting.id == null || meeting.id!.isEmpty) {
      throw Exception('Meeting id is missing');
    }

    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}$_endpoint/${meeting.id}'),
      headers: ApiService.authHeaders,
      body: jsonEncode(meeting.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update meeting');
    }
  }

  /// Delete meeting
  static Future<void> deleteMeeting(String id) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}$_endpoint/$id'),
      headers: ApiService.authHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete meeting');
    }
  }

  /// Get all meetings
  static Future<List<Meeting>> getMeetings() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}$_endpoint'),
      headers: ApiService.authHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch meetings');
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => Meeting.fromJson(e)).toList();
  }
}
