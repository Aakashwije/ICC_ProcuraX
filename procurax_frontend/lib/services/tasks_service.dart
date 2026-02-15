/*
  TasksService

  This service talks to the backend tasks API.
  It wraps HTTP calls and converts JSON into Task models.
*/
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:procurax_frontend/models/task_model.dart';
import 'package:procurax_frontend/services/api_service.dart';

/*
  Service class used by tasks UI screens.
*/
class TasksService {
  /*
    Base URL and auth headers reused for all requests.
  */
  static String get _baseUrl => ApiService.baseUrl;
  static Map<String, String> get _headers => ApiService.authHeaders;

  /*
    Fetch list of tasks.
    If archived=true, backend returns archived tasks only.
  */
  Future<List<Task>> fetchTasks({bool archived = false}) async {
    final query = archived ? "?archived=true" : "";
    final response = await http.get(
      Uri.parse('$_baseUrl/api/tasks$query'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load tasks: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data is! List) return [];
    return data.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
  }

  /*
    Create a new task on the backend.
  */
  Future<Task> createTask(Task task) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/tasks'),
      headers: _headers,
      body: jsonEncode(task.toCreateJson()),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create task: ${response.statusCode}');
    }

    return Task.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /*
    Update an existing task by id.
  */
  Future<Task> updateTask(Task task) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/tasks/${task.id}'),
      headers: _headers,
      body: jsonEncode(task.toUpdateJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update task: ${response.statusCode}');
    }

    return Task.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /*
    Archive a task (soft delete).
  */
  Future<Task> archiveTask(String id) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/api/tasks/$id/archive'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to archive task: ${response.statusCode}');
    }

    return Task.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /*
    Restore a previously archived task.
  */
  Future<Task> restoreTask(String id) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/api/tasks/$id/restore'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to restore task: ${response.statusCode}');
    }

    return Task.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /*
    Permanently delete a task.
  */
  Future<void> deleteTask(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/tasks/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete task: ${response.statusCode}');
    }
  }
}
