import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:procurax_frontend/models/note_model.dart';
import 'package:procurax_frontend/services/api_service.dart';

/// Note Repository
///
/// Handles all data operations for notes.
/// Implements caching and offline support.
class NoteRepository {
  static String get _baseUrl => '${ApiService.baseUrl}/api/v1/notes';
  static Map<String, String> get _headers => ApiService.authHeaders;

  // Local cache
  final Map<String, Note> _cache = {};
  DateTime? _lastFetch;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Check if cache is valid
  bool get _isCacheValid =>
      _lastFetch != null &&
      DateTime.now().difference(_lastFetch!) < _cacheExpiry;

  /// Get all notes with optional caching
  Future<List<Note>> getAll({bool forceRefresh = false, String? tag}) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _isCacheValid && tag == null) {
      return _cache.values.toList();
    }

    final query = tag != null ? '?tag=$tag' : '';
    final response = await http.get(
      Uri.parse('$_baseUrl$query'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw NoteRepositoryException(
        'Failed to load notes',
        response.statusCode,
      );
    }

    final data = jsonDecode(response.body);
    final List<Note> notes = (data['notes'] as List)
        .map((e) => Note.fromJson(e as Map<String, dynamic>))
        .toList();

    // Update cache
    if (tag == null) {
      _cache.clear();
      for (final note in notes) {
        _cache[note.id] = note;
      }
      _lastFetch = DateTime.now();
    }

    return notes;
  }

  /// Get note by ID
  Future<Note> getById(String id) async {
    // Check cache first
    if (_cache.containsKey(id)) {
      return _cache[id]!;
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );

    if (response.statusCode == 404) {
      throw NoteNotFoundException(id);
    }

    if (response.statusCode != 200) {
      throw NoteRepositoryException('Failed to load note', response.statusCode);
    }

    final data = jsonDecode(response.body);
    final note = Note.fromJson(data['note'] as Map<String, dynamic>);

    // Update cache
    _cache[note.id] = note;

    return note;
  }

  /// Create a new note
  Future<Note> create(Note note) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: jsonEncode(note.toJson()),
    );

    if (response.statusCode != 201) {
      throw NoteRepositoryException(
        'Failed to create note',
        response.statusCode,
        _parseError(response.body),
      );
    }

    final data = jsonDecode(response.body);
    final createdNote = Note.fromJson(data['note'] as Map<String, dynamic>);

    // Update cache
    _cache[createdNote.id] = createdNote;

    return createdNote;
  }

  /// Update an existing note
  Future<Note> update(String id, Note note) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
      body: jsonEncode(note.toJson()),
    );

    if (response.statusCode == 404) {
      throw NoteNotFoundException(id);
    }

    if (response.statusCode != 200) {
      throw NoteRepositoryException(
        'Failed to update note',
        response.statusCode,
        _parseError(response.body),
      );
    }

    final data = jsonDecode(response.body);
    final updatedNote = Note.fromJson(data['note'] as Map<String, dynamic>);

    // Update cache
    _cache[updatedNote.id] = updatedNote;

    return updatedNote;
  }

  /// Delete a note
  Future<bool> delete(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );

    if (response.statusCode == 404) {
      throw NoteNotFoundException(id);
    }

    if (response.statusCode != 200) {
      throw NoteRepositoryException(
        'Failed to delete note',
        response.statusCode,
      );
    }

    // Remove from cache
    _cache.remove(id);

    return true;
  }

  /// Get all unique tags
  Future<List<String>> getTags() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/tags'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw NoteRepositoryException('Failed to load tags', response.statusCode);
    }

    final data = jsonDecode(response.body);
    return List<String>.from(data['tags'] ?? []);
  }

  /// Clear the cache
  void clearCache() {
    _cache.clear();
    _lastFetch = null;
  }

  /// Parse error message from response body
  String? _parseError(String body) {
    try {
      final data = jsonDecode(body);
      return data['error']?['message'] ?? data['message'];
    } catch (_) {
      return null;
    }
  }
}

/// Note Repository Exception
class NoteRepositoryException implements Exception {
  final String message;
  final int statusCode;
  final String? details;

  NoteRepositoryException(this.message, this.statusCode, [this.details]);

  @override
  String toString() =>
      'NoteRepositoryException: $message (status: $statusCode)';
}

/// Note Not Found Exception
class NoteNotFoundException implements Exception {
  final String noteId;

  NoteNotFoundException(this.noteId);

  @override
  String toString() => 'Note not found: $noteId';
}
