import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:procurax_frontend/models/task_model.dart';
import 'package:procurax_frontend/services/api_service.dart';

/// Task Repository
///
/// Handles all data operations for tasks.
/// Implements caching and offline support.
class TaskRepository {
  static String get _baseUrl => '${ApiService.baseUrl}/api/v1/tasks';
  static Map<String, String> get _headers => ApiService.authHeaders;

  // Local cache
  final Map<String, Task> _cache = {};
  DateTime? _lastFetch;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Check if cache is valid
  bool get _isCacheValid =>
      _lastFetch != null &&
      DateTime.now().difference(_lastFetch!) < _cacheExpiry;

  /// Get all tasks with optional caching
  Future<List<Task>> getAll({
    bool forceRefresh = false,
    bool archived = false,
  }) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _isCacheValid && !archived) {
      return _cache.values.where((t) => !t.isArchived).toList();
    }

    final query = archived ? '?archived=true' : '';
    final response = await http.get(
      Uri.parse('$_baseUrl$query'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw TaskRepositoryException(
        'Failed to load tasks',
        response.statusCode,
      );
    }

    final data = jsonDecode(response.body);
    final List<Task> tasks = (data['tasks'] as List)
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList();

    // Update cache
    if (!archived) {
      _cache.clear();
      for (final task in tasks) {
        _cache[task.id] = task;
      }
      _lastFetch = DateTime.now();
    }

    return tasks;
  }

  /// Get task by ID
  Future<Task> getById(String id) async {
    // Check cache first
    if (_cache.containsKey(id)) {
      return _cache[id]!;
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );

    if (response.statusCode == 404) {
      throw TaskNotFoundException(id);
    }

    if (response.statusCode != 200) {
      throw TaskRepositoryException('Failed to load task', response.statusCode);
    }

    final data = jsonDecode(response.body);
    final task = Task.fromJson(data['task'] as Map<String, dynamic>);

    // Update cache
    _cache[task.id] = task;

    return task;
  }

  /// Create a new task
  Future<Task> create(Task task) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: jsonEncode(task.toCreateJson()),
    );

    if (response.statusCode != 201) {
      throw TaskRepositoryException(
        'Failed to create task',
        response.statusCode,
        _parseError(response.body),
      );
    }

    final data = jsonDecode(response.body);
    final createdTask = Task.fromJson(data['task'] as Map<String, dynamic>);

    // Update cache
    _cache[createdTask.id] = createdTask;

    return createdTask;
  }

  /// Update an existing task
  Future<Task> update(String id, Task task) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
      body: jsonEncode(task.toUpdateJson()),
    );

    if (response.statusCode == 404) {
      throw TaskNotFoundException(id);
    }

    if (response.statusCode != 200) {
      throw TaskRepositoryException(
        'Failed to update task',
        response.statusCode,
        _parseError(response.body),
      );
    }

    final data = jsonDecode(response.body);
    final updatedTask = Task.fromJson(data['task'] as Map<String, dynamic>);

    // Update cache
    _cache[updatedTask.id] = updatedTask;

    return updatedTask;
  }

  /// Archive a task
  Future<Task> archive(String id) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/$id/archive'),
      headers: _headers,
    );

    if (response.statusCode == 404) {
      throw TaskNotFoundException(id);
    }

    if (response.statusCode != 200) {
      throw TaskRepositoryException(
        'Failed to archive task',
        response.statusCode,
      );
    }

    final data = jsonDecode(response.body);
    final archivedTask = Task.fromJson(data['task'] as Map<String, dynamic>);

    // Remove from active cache
    _cache.remove(id);

    return archivedTask;
  }

  /// Restore an archived task
  Future<Task> restore(String id) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/$id/restore'),
      headers: _headers,
    );

    if (response.statusCode == 404) {
      throw TaskNotFoundException(id);
    }

    if (response.statusCode != 200) {
      throw TaskRepositoryException(
        'Failed to restore task',
        response.statusCode,
      );
    }

    final data = jsonDecode(response.body);
    final restoredTask = Task.fromJson(data['task'] as Map<String, dynamic>);

    // Add back to cache
    _cache[restoredTask.id] = restoredTask;

    return restoredTask;
  }

  /// Delete a task permanently
  Future<bool> delete(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );

    if (response.statusCode == 404) {
      throw TaskNotFoundException(id);
    }

    if (response.statusCode != 200) {
      throw TaskRepositoryException(
        'Failed to delete task',
        response.statusCode,
      );
    }

    // Remove from cache
    _cache.remove(id);

    return true;
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

/// Task Repository Exception
class TaskRepositoryException implements Exception {
  final String message;
  final int statusCode;
  final String? details;

  TaskRepositoryException(this.message, this.statusCode, [this.details]);

  @override
  String toString() =>
      'TaskRepositoryException: $message (status: $statusCode)';
}

/// Task Not Found Exception
class TaskNotFoundException implements Exception {
  final String taskId;

  TaskNotFoundException(this.taskId);

  @override
  String toString() => 'Task not found: $taskId';
}
