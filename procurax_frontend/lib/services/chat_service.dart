import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:procurax_frontend/services/api_service.dart';

class ChatService {
  static String get _baseUrl => ApiService.baseUrl;
  static Map<String, String> get _headers => ApiService.authHeaders;

  Future<Map<String, dynamic>> createChat({
    required List<String> members,
    required bool isGroup,
    String? name,
  }) async {
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
  }

  Future<List<dynamic>> getUserChats(String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/chats/user/$userId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load chats: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    return (data is List) ? data : [];
  }

  Future<Map<String, dynamic>> getChatById(String chatId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/chats/$chatId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load chat: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> markChatRead({
    required String chatId,
    required String userId,
  }) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/api/chats/$chatId/read'),
      headers: _headers,
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark chat read: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    required String type,
    String? fileUrl,
    String? fileName,
  }) async {
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
  }

  Future<List<dynamic>> getMessagesByChat(String chatId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/messages?chatId=$chatId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load messages: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    return (data is List) ? data : [];
  }

  Future<Map<String, dynamic>> uploadFile({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/files/upload'),
    );

    request.headers.addAll(_headers);
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to upload file: ${response.statusCode}');
    }

    return jsonDecode(responseBody) as Map<String, dynamic>;
  }

  Future<void> sendPresenceHeartbeat(String userId) async {
    await http.post(
      Uri.parse('$_baseUrl/api/presence/heartbeat'),
      headers: _headers,
      body: jsonEncode({'userId': userId}),
    );
  }

  Future<Map<String, dynamic>> getPresence(String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/presence/$userId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get presence: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> setTyping({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    await http.post(
      Uri.parse('$_baseUrl/api/typing'),
      headers: _headers,
      body: jsonEncode({
        'chatId': chatId,
        'userId': userId,
        'isTyping': isTyping,
      }),
    );
  }

  Future<Map<String, dynamic>> getTyping({
    required String chatId,
    required String userId,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/typing?chatId=$chatId&userId=$userId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get typing: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getUserAlerts(String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/alerts/user/$userId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load alerts: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    return (data is List) ? data : [];
  }

  Future<void> markAlertsRead({
    required String userId,
    required String chatId,
  }) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/api/alerts/read'),
      headers: _headers,
      body: jsonEncode({'userId': userId, 'chatId': chatId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark alerts read: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getAllUsers() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/users/all'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load users: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    return (data is List) ? data : [];
  }

  //Delete chat
  Future<Map<String, dynamic>> deleteMessage({
    required String messageId,
    required String userId,
  }) async {
    final response = await http
        .delete(
          Uri.parse('$_baseUrl/api/messages/$messageId'),
          headers: _headers,
          body: jsonEncode({'userId': userId}),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Failed to delete message (${response.statusCode}): ${response.body}',
    );
  }
}
