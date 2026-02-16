import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_service.dart';
import '../pages/meetings/features/smart_calendar/models/meeting.dart';

class MeetingsService {
  static const String _endpoint = '/api/meetings';

  static String _extractErrorMessage(http.Response response) {
    if (response.body.isEmpty) {
      return 'Request failed with status ${response.statusCode}';
    }

    try {
      final data = jsonDecode(response.body);
      if (data is Map && data['message'] != null) {
        if (data['conflicts'] is List &&
            (data['conflicts'] as List).isNotEmpty) {
          final conflicts = data['conflicts'] as List;
          final first = conflicts.first;
          if (first is Map &&
              first['startTime'] != null &&
              first['endTime'] != null) {
            return '${data['message']} (conflicts: ${conflicts.length}, first: ${first['startTime']} → ${first['endTime']})';
          }
          return '${data['message']} (conflicts: ${conflicts.length})';
        }
        return data['message'].toString();
      }
      if (data is Map && data['error'] != null) {
        return data['error'].toString();
      }
    } catch (_) {
      // ignore parse errors and fall back to raw body
    }

    return 'Request failed (${response.statusCode}): ${response.body}';
  }

  /// Create meeting
  static Future<void> addMeeting(Meeting meeting) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}$_endpoint'),
      headers: ApiService.authHeaders,
      body: jsonEncode(meeting.toJson()),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response));
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
      throw Exception(_extractErrorMessage(response));
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
