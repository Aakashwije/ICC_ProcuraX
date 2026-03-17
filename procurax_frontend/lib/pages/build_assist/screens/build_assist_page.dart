import 'package:flutter/material.dart';
import '../widgets/ai_message.dart';
import '../widgets/user_message.dart';
import '../widgets/delivery_card.dart';
import '../widgets/bottom_input.dart';
import 'package:procurax_frontend/widgets/app_drawer.dart';
import 'package:procurax_frontend/routes/app_routes.dart';
import 'package:procurax_frontend/services/api_service.dart';
import 'package:procurax_frontend/theme/app_theme.dart' as theme;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';

class BuildAssistPage extends StatefulWidget {
  const BuildAssistPage({super.key});

  @override
  State<BuildAssistPage> createState() => _BuildAssistPageState();
}

class _BuildAssistPageState extends State<BuildAssistPage> {
  final List<Map<String, dynamic>> messages = [];
  final TextEditingController _messageController = TextEditingController();
  bool isLoading = false;
  final ScrollController _scrollController = ScrollController();

  String get baseUrl {
    // Android emulator uses 10.0.2.2, others use localhost
    return Platform.isAndroid
        ? 'http://10.0.2.2:5002'
        : 'http://127.0.0.1:5002';
  }

  @override
  void initState() {
    super.initState();
    messages.add({
      'type': 'ai',
      'message':
          "Hello! I'm your BuildAssist AI.\nHow can I help you with your construction project today?",
      'timestamp': _getCurrentTime(),
      'showSuggestions': true,
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    print('Sending message: $userMessage');

    // Add user message to UI
    setState(() {
      messages.add({
        'type': 'user',
        'message': userMessage,
        'timestamp': _getCurrentTime(),
      });
      isLoading = true;
    });

    _scrollToBottom();

    try {
      // Get auth token from ApiService (optional - not required)
      final token = ApiService.token;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      // Add timeout to prevent hanging
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/buildassist'),
            headers: headers,
            body: jsonEncode({'message': userMessage}),
          )
          .timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 401) {
        final data = jsonDecode(response.body);
        print('Response type: ${data['type']}');
        print('Response data type: ${data['data']?.runtimeType}');
        print('Response data: ${data['data']}');
        print('Received data: $data');
        print('type = ${data['type']}');
        print('FULL RESPONSE: $data');
        print('TYPE: ${data['type']}');
        print('REPLY: ${data['reply']}');
        print('data runtimeType = ${data['data']?.runtimeType}');
        setState(() {
          final responseType = data['type'] ?? 'ai';
          final reply = data['reply'] ?? 'No reply';
          final responseData = data['data'];

          // Handle different response types
          if (responseType == 'meetings_data' ||
              responseType == 'tasks_data' ||
              responseType == 'notes_data' ||
              responseType == 'procurement_data') {
            // Add message with data
            messages.add({
              'type': responseType,
              'message': reply,
              'data': responseData,
              'timestamp': _getCurrentTime(),
              'showSuggestions': false,
            });
          } else if (responseType == 'meeting_scheduled') {
            messages.add({
              'type': 'success',
              'message': reply,
              'timestamp': _getCurrentTime(),
              'showSuggestions': false,
            });
          } else if (responseType == 'dashboard_data') {
            messages.add({
              'type': 'ai',
              'message': reply,
              'timestamp': _getCurrentTime(),
              'showSuggestions': false,
            });
          } else {
            // Default AI message
            messages.add({
              'type': 'ai',
              'message': reply,
              'timestamp': _getCurrentTime(),
              'showSuggestions': responseType == 'help',
            });
          }
          isLoading = false;
        });

        _scrollToBottom();
      } else {
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } on TimeoutException catch (_) {
      print('Timeout error');
      setState(() {
        messages.add({
          'type': 'ai',
          'message':
              'The request timed out. Please check if the backend server is running.',
          'timestamp': _getCurrentTime(),
          'showSuggestions': true,
        });
        isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        messages.add({
          'type': 'ai',
          'message':
              'Connection error. Make sure the backend is running on port 5002.',
          'timestamp': _getCurrentTime(),
          'showSuggestions': true,
        });
        isLoading = false;
      });
    }
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
  }

  void handleQuickAction(String action) {
    // Map button labels to BuildAssist queries
    final queryMap = {
      'Schedule': 'show upcoming meetings',
      'Schedule Update': 'show upcoming meetings',
      'Schedule Meetings': 'show upcoming meetings',
      'Schedule Meeting': 'schedule a new meeting',
      'Tasks': 'show pending tasks',
      'Notes': 'show all notes',
      'Material Status': 'show procurement status',
    };

    final query = queryMap[action] ?? action;
    sendMessage(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AppDrawer(currentRoute: AppRoutes.buildAssist),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: theme.AppResponsive.pagePadding(
                context,
              ).copyWith(bottom: 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Builder(
                      builder: (context) => Semantics(
                        label: 'Open navigation menu',
                        button: true,
                        child: IconButton(
                          tooltip: 'Menu',
                          icon: Icon(
                            Icons.menu_rounded,
                            size: 30,
                            color: theme.AppColors.primary,
                          ),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    "BuildAssist",
                    style: theme.AppTextStyles.h2.copyWith(
                      color: theme.AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Chat Area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  if (msg['type'] == 'user') {
                    return Column(
                      children: [
                        UserMessage(
                          message: msg['message'],
                          timestamp: msg['timestamp'],
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  } else if (msg['type'] == 'procurement_data') {
                    return Column(
                      children: [
                        AIMessage(
                          message: msg['message'],
                          timestamp: msg['timestamp'],
                          showSuggestions: false,
                          onSuggestionTap: handleQuickAction,
                        ),
                        const SizedBox(height: 12),
                        if (msg['data'] is List)
                          ...(msg['data'] as List)
                              .map(
                                (item) => Column(
                                  children: [
                                    DeliveryCard(
                                      data: Map<String, dynamic>.from(
                                        item is Map
                                            ? item
                                            : {'title': item.toString()},
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              )
                              .toList()
                        else if (msg['data'] != null)
                          Column(
                            children: [
                              DeliveryCard(
                                data: Map<String, dynamic>.from(
                                  msg['data'] is Map
                                      ? msg['data']
                                      : {'title': msg['data'].toString()},
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        const SizedBox(height: 8),
                      ],
                    );
                  } else if (msg['type'] == 'ai_delivery') {
                    return Column(
                      children: [
                        DeliveryCard(
                          data: Map<String, dynamic>.from(
                            msg['data'] is Map
                                ? msg['data']
                                : {'title': msg['data'].toString()},
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  } else if (msg['type'] == 'meetings_data' ||
                      msg['type'] == 'tasks_data' ||
                      msg['type'] == 'notes_data') {
                    return Column(
                      children: [
                        // Show the reply text first
                        AIMessage(
                          message: msg['message'],
                          timestamp: msg['timestamp'],
                          showSuggestions: false,
                          onSuggestionTap: handleQuickAction,
                        ),
                        const SizedBox(height: 12),
                        // Then show the data as cards
                        if (msg['data'] is List)
                          ...(msg['data'] as List)
                              .map(
                                (item) => Column(
                                  children: [
                                    DeliveryCard(
                                      data: Map<String, dynamic>.from(
                                        item is Map
                                            ? item
                                            : {'title': item.toString()},
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              )
                              .toList()
                        else if (msg['data'] != null)
                          Column(
                            children: [
                              DeliveryCard(
                                data: Map<String, dynamic>.from(
                                  msg['data'] is Map
                                      ? msg['data']
                                      : {'title': msg['data'].toString()},
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        const SizedBox(height: 8),
                      ],
                    );
                  } else if (msg['type'] == 'success') {
                    return Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.green.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade600,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  msg['message'],
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        AIMessage(
                          message: msg['message'],
                          timestamp: msg['timestamp'],
                          showSuggestions: msg['showSuggestions'] ?? false,
                          onSuggestionTap: handleQuickAction,
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  }
                },
              ),
            ),

            // Quick Actions
            if (!isLoading)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: Colors.white,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickAction("Schedule Meeting"),
                      _buildQuickAction("Material Status"),
                      _buildQuickAction("Notes"),
                      _buildQuickAction("Tasks"),
                    ],
                  ),
                ),
              ),

            // Bottom Input
            BottomInput(
              controller: _messageController,
              onSend: sendMessage,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => handleQuickAction(text),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: theme.AppColors.neutral100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(text, style: theme.AppTextStyles.labelSmall),
        ),
      ),
    );
  }
}
