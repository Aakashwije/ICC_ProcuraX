import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:procurax_frontend/models/note_model.dart';
import 'package:procurax_frontend/services/api_service.dart';

/// Service class that handles all HTTP communication with the Notes API.
///
/// Every method is static so callers don't need an instance.
/// The base endpoint is built from [ApiService.baseUrl] so it
/// automatically points to the correct Railway deployment URL.
///
/// All methods:
/// - Attach the JWT Bearer token via [ApiService.authHeaders]
/// - Apply a sensible timeout to avoid hanging UI
/// - Throw a descriptive [Exception] on failure so the UI can show
///   a meaningful error message
class NotesService {
  /// Base REST endpoint for all note operations.
  static String get _endpoint => "${ApiService.baseUrl}/api/notes";

  /// Fetches all notes for the authenticated user.
  ///
  /// Returns notes sorted by most recently edited (backend handles ordering).
  /// Throws on network error or non-200 status.
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

  /// Creates a new note on the backend.
  ///
  /// The [note] object is serialised via [Note.toJson]. The backend
  /// returns the persisted document (with the real MongoDB `_id`) which
  /// is deserialised back into a [Note] and returned to the caller.
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

  /// Updates an existing note identified by [note.id].
  ///
  /// Sends the full note body via PUT. The backend updates `lastEdited`
  /// automatically and returns the updated document.
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

  /// Permanently deletes the note with the given [id].
  ///
  /// Also removes the note from the backend's notification records.
  /// Throws if the note is not found or the user is not the owner.
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

  /// Uploads a file attachment to an existing note via a multipart POST.
  ///
  /// How it works:
  /// 1. Builds an [http.MultipartRequest] with the file at [filePath].
  /// 2. Attaches the JWT token in the Authorization header.
  /// 3. The backend (multer) reads the file buffer and uploads it to
  ///    Cloudinary, then stores the URL and filename on the note document.
  /// 4. Returns the JSON response containing [attachmentUrl] and
  ///    [attachmentName] on success.
  ///
  /// A longer timeout (30 s) is used because file uploads can be slow
  /// on mobile networks.
  /// Upload a file attachment to a note via multipart POST.
  static Future<Map<String, dynamic>> uploadAttachment(
    String noteId,
    String filePath,
    String fileName,
  ) async {
    try {
      final uri = Uri.parse("$_endpoint/$noteId/attachment");
      final request = http.MultipartRequest("POST", uri);
      request.headers["Authorization"] =
          ApiService.authHeaders["Authorization"]!;
      request.files.add(
        await http.MultipartFile.fromPath("file", filePath, filename: fileName),
      );

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        throw Exception(
          "Failed to upload attachment (status ${response.statusCode})",
        );
      }

      return json.decode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      throw Exception("Upload timed out. Check your connection.");
    }
  }

  /// Deletes the attachment from both Cloudinary and the note document.
  ///
  /// After this call the note's [hasAttachment] flag is set to false and
  /// [attachmentUrl] / [attachmentName] are cleared on the backend.
  /// Delete an attachment from a note.
  static Future<void> deleteAttachment(String noteId) async {
    try {
      final response = await http
          .delete(
            Uri.parse("$_endpoint/$noteId/attachment"),
            headers: ApiService.authHeaders,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          "Failed to delete attachment (status ${response.statusCode})",
        );
      }
    } on TimeoutException {
      throw Exception("Request timed out.");
    }
  }
}
