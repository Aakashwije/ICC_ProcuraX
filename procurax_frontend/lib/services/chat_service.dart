import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:procurax_frontend/services/api_service.dart';

class ChatService {
  static String get _baseUrl => ApiService.baseUrl;
  static Map<String, String> get _headers => ApiService.authHeaders;

  /// Create a new chat
  Future<Map<String, dynamic>> createChat({
    required List<String> members,
    required bool isGroup,
    String? name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/chats'),
        headers: _headers,
        body: jsonEncode({
          'members': members,
          'isGroup': isGroup,
          if (name != null) 'name': name,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create chat: ${response.statusCode}');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all chats for a user
  Future<List<dynamic>> getUserChats(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/chats/user/$userId'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load chats: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      return (data is List) ? data : [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get chat by ID
  Future<Map<String, dynamic>> getChatById(String chatId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/chats/$chatId'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load chat: ${response.statusCode}');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Mark chat as read for a user
  Future<void> markChatRead({
    required String chatId,
    required String userId,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/api/chats/$chatId/read'),
        headers: _headers,
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark chat read: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Send a message
  Future<Map<String, dynamic>> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    required String type,
    String? fileUrl,
    String? fileName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/messages'),
        headers: _headers,
        body: jsonEncode({
          'chatId': chatId,
          'senderId': senderId,
          'content': content,
          'type': type,
          if (fileUrl != null) 'fileUrl': fileUrl,
          if (fileName != null) 'fileName': fileName,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to send message: ${response.statusCode}');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Get messages by chat ID
  Future<List<dynamic>> getMessagesByChat(String chatId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/messages?chatId=$chatId'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      return (data is List) ? data : [];
    } catch (e) {
      rethrow;
    }
  }

  /// Upload a file
  Future<Map<String, dynamic>> uploadFile({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/files/upload'),
      );

      request.headers.addAll(_headers);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to upload file: ${response.statusCode}');
      }

      return jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Send presence heartbeat
  Future<void> sendPresenceHeartbeat(String userId) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/presence/heartbeat'),
        headers: _headers,
        body: jsonEncode({'userId': userId}),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get presence status
  Future<Map<String, dynamic>> getPresence(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/presence/$userId'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get presence: ${response.statusCode}');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Set typing status
  Future<void> setTyping({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/typing'),
        headers: _headers,
        body: jsonEncode({
          'chatId': chatId,
          'userId': userId,
          'isTyping': isTyping,
        }),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get typing status
  Future<Map<String, dynamic>> getTyping({
    required String chatId,
    required String userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/typing?chatId=$chatId&userId=$userId'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get typing status: ${response.statusCode}');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all users
  Future<List<dynamic>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/users/all'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load users: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      return (data is List) ? data : [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get user alerts
  Future<List<dynamic>> getUserAlerts(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/alerts/user/$userId'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load alerts: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      return (data is List) ? data : [];
    } catch (e) {
      rethrow;
    }
  }

  /// Mark alerts as read
  Future<void> markAlertsRead({
    required String userId,
    required String chatId,
  }) async {
    try {
      await http.patch(
        Uri.parse('$_baseUrl/api/alerts/read'),
        headers: _headers,
        body: jsonEncode({
          'userId': userId,
          'chatId': chatId,
        }),
      );
    } catch (e) {
      rethrow;
    }
  }
}
