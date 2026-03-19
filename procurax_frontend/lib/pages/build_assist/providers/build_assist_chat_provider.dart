import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:procurax_frontend/services/api_service.dart';

/// Keeps BuildAssist chat messages alive across navigation.
/// Registered as a ChangeNotifierProvider in main.dart so the
/// message list is preserved when the user leaves and returns.
class BuildAssistChatProvider extends ChangeNotifier {
  /// In-memory chat history — survives navigation but resets on app restart.
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  /// Public read-only access to the chat messages list.
  List<Map<String, dynamic>> get messages => _messages;

  /// True while waiting for a backend response.
  bool get isLoading => _isLoading;

  BuildAssistChatProvider() {
    _addWelcomeMessage();
  }

  /// Adds the initial welcome message if the chat is empty.
  void _addWelcomeMessage() {
    if (_messages.isEmpty) {
      _messages.add({
        'type': 'ai',
        'message':
            "Hello! I'm your BuildAssist AI.\nHow can I help you with your construction project today?",
        'timestamp': _getCurrentTime(),
        'showSuggestions': true,
      });
    }
  }

  /// Clear all messages and start fresh.
  void clearChat() {
    _messages.clear();
    _addWelcomeMessage();
    notifyListeners();
  }

  /// Sends a user message to the BuildAssist backend and appends
  /// both the user message and the AI response to the chat history.
  Future<void> sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    _messages.add({
      'type': 'user',
      'message': userMessage,
      'timestamp': _getCurrentTime(),
    });
    _isLoading = true;
    notifyListeners(); // Update UI immediately with user bubble + loader

    try {
      // Attach auth token if available (optional — unauthenticated queries still work)
      final token = ApiService.token;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/api/buildassist'),
            headers: headers,
            body: jsonEncode({'message': userMessage}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 401) {
        final data = jsonDecode(response.body);
        final responseType = data['type'] ?? 'ai';
        final reply = data['reply'] ?? 'No reply';
        final responseData = data['data'];

        // Route response into the appropriate message format
        // based on the type returned by the backend.
        if (responseType == 'note_created' ||
            responseType == 'task_added' ||
            responseType == 'meeting_scheduled') {
          _messages.add({
            'type': 'ai',
            'message': reply,
            'timestamp': _getCurrentTime(),
            'showSuggestions': true,
          });
        } else if (responseType == 'meetings_data' ||
            responseType == 'tasks_data' ||
            responseType == 'notes_data' ||
            responseType == 'procurement_data') {
          _messages.add({
            'type': responseType,
            'message': reply,
            'data': responseData,
            'timestamp': _getCurrentTime(),
            'showSuggestions': false,
          });
        } else if (responseType == 'dashboard_data') {
          _messages.add({
            'type': 'dashboard_data',
            'message': reply,
            'data': responseData,
            'timestamp': _getCurrentTime(),
            'showSuggestions': false,
          });
        } else {
          _messages.add({
            'type': 'ai',
            'message': reply,
            'timestamp': _getCurrentTime(),
            'showSuggestions': responseType == 'help',
          });
        }
      } else {
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } on TimeoutException catch (_) {
      _messages.add({
        'type': 'ai',
        'message':
            'The request timed out. Please check if the backend server is running.',
        'timestamp': _getCurrentTime(),
        'showSuggestions': true,
      });
    } catch (e) {
      debugPrint('BuildAssist error: $e');
      _messages.add({
        'type': 'ai',
        'message':
            'Connection error. Make sure the backend is running on port 5002.',
        'timestamp': _getCurrentTime(),
        'showSuggestions': true,
      });
    } finally {
      _isLoading = false;
      notifyListeners(); // Remove loader and render latest message
    }
  }

  /// Returns a formatted timestamp string for the current moment.
  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
  }
}
