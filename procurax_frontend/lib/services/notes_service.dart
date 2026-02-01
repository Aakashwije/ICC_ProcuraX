import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:procurax_frontend/models/note_model.dart';
import 'package:procurax_frontend/services/api_service.dart';

class NotesService {
  static String get _endpoint => "${ApiService.baseUrl}/api/notes";

  static Future<List<Note>> fetchNotes() async {
    try {
      final response = await http
          .get(Uri.parse(_endpoint), headers: ApiService.authHeaders)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception("Failed to load notes (status ${response.statusCode})");
      }

      final List<dynamic> data = json.decode(response.body) as List<dynamic>;
      return data
          .map((item) => Note.fromJson(item as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      throw Exception(
        "Request timed out. Check the backend at ${ApiService.baseUrl}.",
      );
    } on http.ClientException catch (err) {
      throw Exception(
        "Network error: ${err.message}. Check backend URL and device network.",
      );
    }
  }

  static Future<Note> createNote(Note note) async {
    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: ApiService.authHeaders,
            body: json.encode(note.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 201) {
        throw Exception(
          "Failed to create note (status ${response.statusCode})",
        );
      }

      final Map<String, dynamic> data =
          json.decode(response.body) as Map<String, dynamic>;
      return Note.fromJson(data);
    } on TimeoutException {
      throw Exception(
        "Request timed out. Check the backend at ${ApiService.baseUrl}.",
      );
    } on http.ClientException catch (err) {
      throw Exception(
        "Network error: ${err.message}. Check backend URL and device network.",
      );
    }
  }

  static Future<Note> updateNote(Note note) async {
    try {
      final response = await http
          .put(
            Uri.parse("$_endpoint/${note.id}"),
            headers: ApiService.authHeaders,
            body: json.encode(note.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          "Failed to update note (status ${response.statusCode})",
        );
      }

      final Map<String, dynamic> data =
          json.decode(response.body) as Map<String, dynamic>;
      return Note.fromJson(data);
    } on TimeoutException {
      throw Exception(
        "Request timed out. Check the backend at ${ApiService.baseUrl}.",
      );
    } on http.ClientException catch (err) {
      throw Exception(
        "Network error: ${err.message}. Check backend URL and device network.",
      );
    }
  }

  static Future<void> deleteNote(String id) async {
    try {
      final response = await http
          .delete(Uri.parse("$_endpoint/$id"), headers: ApiService.authHeaders)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          "Failed to delete note (status ${response.statusCode})",
        );
      }
    } on TimeoutException {
      throw Exception(
        "Request timed out. Check the backend at ${ApiService.baseUrl}.",
      );
    } on http.ClientException catch (err) {
      throw Exception(
        "Network error: ${err.message}. Check backend URL and device network.",
      );
    }
  }
}
