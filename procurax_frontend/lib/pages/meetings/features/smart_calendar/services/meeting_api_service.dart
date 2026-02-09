import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meeting.dart';

class MeetingApiService {
  static const String baseUrl = 'http://localhost:5000/api/meetings';

  Future<List<Meeting>> getMeetings() async {
    final res = await http.get(Uri.parse(baseUrl));

    if (res.statusCode != 200) {
      throw Exception('Failed to load meetings');
    }

    final List data = json.decode(res.body);
    return data.map((e) => Meeting.fromJson(e)).toList();
  }

  Future<void> createMeeting(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (res.statusCode != 201) {
      throw Exception(res.body);
    }
  }
}
