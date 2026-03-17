import 'package:flutter/material.dart';
import '../widgets/ai_message.dart';
import '../widgets/user_message.dart';
import '../widgets/delivery_card.dart';
import '../widgets/bottom_input.dart';
import '../widgets/suggestion_chip.dart';
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
      'suggestions': [
        'Show my meetings',
        'Show my tasks',
        'Material status',
        'Dashboard summary',
      ],
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

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/buildassist'),
            headers: headers,
            body: jsonEncode({'message': userMessage}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 401) {
        final data = jsonDecode(response.body);
        final List<String> suggestions = data['suggestions'] != null
            ? List<String>.from(data['suggestions'])
            : [];
        setState(() {
          final responseType = data['type'] ?? 'ai';
          final reply = data['reply'] ?? 'No reply';
          final responseData = data['data'];

          // Handle different response types
          if (responseType == 'meetings_data' ||
              responseType == 'tasks_data' ||
              responseType == 'notes_data' ||
              responseType == 'procurement_data') {
            messages.add({
              'type': responseType,
              'message': reply,
              'data': responseData,
              'timestamp': _getCurrentTime(),
              'showSuggestions': suggestions.isNotEmpty,
              'suggestions': suggestions,
            });
          } else if (responseType == 'meeting_scheduled' ||
              responseType == 'note_created' ||
              responseType == 'task_added') {
            messages.add({
              'type': 'success',
              'message': reply,
              'successType': responseType,
              'timestamp': _getCurrentTime(),
              'showSuggestions': suggestions.isNotEmpty,
              'suggestions': suggestions,
            });
          } else if (responseType == 'guide') {
            messages.add({
              'type': 'ai',
              'message': reply,
              'timestamp': _getCurrentTime(),
              'showSuggestions': false,
              'suggestions': [],
            });
          } else if (responseType == 'dashboard_data') {
            messages.add({
              'type': 'ai',
              'message': reply,
              'timestamp': _getCurrentTime(),
              'showSuggestions': suggestions.isNotEmpty,
              'suggestions': suggestions,
            });
          } else {
            messages.add({
              'type': 'ai',
              'message': reply,
              'timestamp': _getCurrentTime(),
              'showSuggestions':
                  responseType == 'help' || suggestions.isNotEmpty,
              'suggestions': suggestions,
            });
          }
          isLoading = false;
        });

        _scrollToBottom();
      } else {
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } on TimeoutException catch (_) {
      setState(() {
        messages.add({
          'type': 'error',
          'message':
              'The request timed out. Please check your connection and try again.',
          'timestamp': _getCurrentTime(),
          'showSuggestions': false,
        });
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        messages.add({
          'type': 'error',
          'message':
              'Something went wrong. Please make sure the backend server is running.',
          'timestamp': _getCurrentTime(),
          'showSuggestions': false,
        });
        isLoading = false;
      });
    }
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12
        ? now.hour - 12
        : (now.hour == 0 ? 12 : now.hour);
    return '$hour:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
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
      'Create Note': 'create a new note',
      'Create Task': 'add a new task',
      'Dashboard': 'dashboard summary',
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
                itemCount: messages.length + (isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  // Typing indicator at the end
                  if (index == messages.length && isLoading) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: theme.AppColors.primary,
                            child: const Text(
                              "BA",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: theme.AppShadows.card,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Thinking...",
                                  style: theme.AppTextStyles.caption.copyWith(
                                    color: theme.AppColors.neutral500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
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
                  } else if (msg['type'] == 'error') {
                    return Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.AppColors.errorLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.AppColors.error.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: theme.AppColors.error,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  msg['message'],
                                  style: theme.AppTextStyles.bodySmall.copyWith(
                                    color: theme.AppColors.error,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.refresh,
                                  color: theme.AppColors.error,
                                  size: 20,
                                ),
                                tooltip: 'Retry',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  // Retry last user message
                                  final lastUserMsg = messages.reversed
                                      .firstWhere(
                                        (m) => m['type'] == 'user',
                                        orElse: () => <String, dynamic>{},
                                      );
                                  if (lastUserMsg.isNotEmpty) {
                                    sendMessage(lastUserMsg['message']);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  } else if (msg['type'] == 'procurement_data') {
                    return Column(
                      children: [
                        AIMessage(
                          message: msg['message'],
                          timestamp: msg['timestamp'],
                          showSuggestions: msg['showSuggestions'] ?? false,
                          suggestions: msg['suggestions'] != null
                              ? List<String>.from(msg['suggestions'])
                              : [],
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
                          showSuggestions: msg['showSuggestions'] ?? false,
                          suggestions: msg['suggestions'] != null
                              ? List<String>.from(msg['suggestions'])
                              : [],
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
                    final successType = msg['successType'] ?? '';
                    IconData successIcon;
                    Color successColor;
                    if (successType == 'note_created') {
                      successIcon = Icons.note_add;
                      successColor = Colors.purple;
                    } else if (successType == 'task_added') {
                      successIcon = Icons.task_alt;
                      successColor = Colors.blue;
                    } else {
                      successIcon = Icons.check_circle;
                      successColor = Colors.green;
                    }
                    return Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: successColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: successColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    successIcon,
                                    color: successColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      msg['message'],
                                      style: theme.AppTextStyles.bodySmall
                                          .copyWith(
                                            color: theme.AppColors.neutral900,
                                            height: 1.5,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              if (msg['suggestions'] != null &&
                                  (msg['suggestions'] as List).isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: (msg['suggestions'] as List<String>)
                                      .map(
                                        (s) => SuggestionChip(
                                          label: s,
                                          onTap: () => handleQuickAction(s),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
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
                          suggestions: msg['suggestions'] != null
                              ? List<String>.from(msg['suggestions'])
                              : [],
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
                      _buildQuickAction(
                        "Schedule Meeting",
                        Icons.calendar_month,
                      ),
                      _buildQuickAction(
                        "Material Status",
                        Icons.inventory_2_outlined,
                      ),
                      _buildQuickAction("Notes", Icons.note_outlined),
                      _buildQuickAction("Tasks", Icons.checklist),
                      _buildQuickAction("Create Note", Icons.note_add_outlined),
                      _buildQuickAction("Create Task", Icons.add_task),
                      _buildQuickAction("Dashboard", Icons.dashboard_outlined),
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

  Widget _buildQuickAction(String text, [IconData? icon]) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => handleQuickAction(text),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: theme.AppColors.neutral100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.AppColors.neutral300.withOpacity(0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: theme.AppColors.primary),
                const SizedBox(width: 6),
              ],
              Text(text, style: theme.AppTextStyles.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
