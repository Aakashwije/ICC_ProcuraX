import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meeting.dart';

class MeetingApiService {
  static const String baseUrl = 'http://localhost:5000/api/meetings';

  // Simple headers - NO AUTH
  Future<Map<String, String>> _headers() async {
    return {'Content-Type': 'application/json'};
  }

  // GET all meetings
  Future<List<Meeting>> getMeetings() async {
    try {
      final headers = await _headers();
      final res = await http.get(Uri.parse(baseUrl), headers: headers);

      if (res.statusCode != 200) {
        throw Exception('Failed to load meetings: ${res.statusCode}');
      }

      final List data = json.decode(res.body);
      return data.map((e) => Meeting.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching meetings: $e');
      rethrow;
    }
  }

  // CREATE meeting
  Future<Meeting> createMeeting(Meeting meeting) async {
    try {
      final headers = await _headers();
      final res = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: json.encode(meeting.toJson()),
      );

      // Handle conflict
      if (res.statusCode == 409) {
        final data = json.decode(res.body);
        throw MeetingConflictException(
          message: data['message'],
          conflicts: data['conflicts'],
          suggestion: data['suggestion'] != null
              ? SuggestedSlot.fromJson(data['suggestion'])
              : null,
        );
      }

      if (res.statusCode != 201) {
        throw Exception('Failed to create meeting: ${res.statusCode}');
      }

      return Meeting.fromJson(json.decode(res.body));
    } catch (e) {
      print('Error creating meeting: $e');
      rethrow;
    }
  }

  // UPDATE meeting
  Future<Meeting> updateMeeting(String id, Meeting meeting) async {
    final headers = await _headers();
    final res = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
      body: json.encode(meeting.toJson()),
    );

    if (res.statusCode == 409) {
      final data = json.decode(res.body);
      throw MeetingConflictException(
        message: data['message'],
        conflicts: data['conflicts'],
      );
    }

    if (res.statusCode != 200) {
      throw Exception('Failed to update meeting');
    }

    return Meeting.fromJson(json.decode(res.body));
  }

  Future<Meeting> markMeetingDone(String id) async {
    final headers = await _headers();
    final res = await http.patch(
      Uri.parse('$baseUrl/$id/done'),
      headers: headers,
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to mark meeting as done');
    }

    return Meeting.fromJson(json.decode(res.body));
  }

  // DELETE meeting
  Future<void> deleteMeeting(String id) async {
    final headers = await _headers();
    final res = await http.delete(Uri.parse('$baseUrl/$id'), headers: headers);

    if (res.statusCode != 200) {
      throw Exception('Failed to delete meeting');
    }
  }
}

// Conflict exception class
class MeetingConflictException implements Exception {
  final String message;
  final List? conflicts;
  final SuggestedSlot? suggestion;

  MeetingConflictException({
    required this.message,
    this.conflicts,
    this.suggestion,
  });

  @override
  String toString() => message;
}

// Suggested slot class
class SuggestedSlot {
  final DateTime suggestedStart;
  final DateTime suggestedEnd;

  SuggestedSlot({required this.suggestedStart, required this.suggestedEnd});

  factory SuggestedSlot.fromJson(Map<String, dynamic> json) {
    return SuggestedSlot(
      suggestedStart: DateTime.parse(json['suggestedStart']),
      suggestedEnd: DateTime.parse(json['suggestedEnd']),
    );
  }
}
