import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/colors.dart';
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
            Uri.parse('${ApiService.baseUrl}/api/buildassist'),
            headers: headers,
            body: jsonEncode({'message': userMessage}),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 401) {
        final data = jsonDecode(response.body);
        debugPrint('Received data: $data');

        setState(() {
          final responseType = data['type'] ?? 'ai';
          final reply = data['reply'] ?? 'No reply';
          final responseData = data['data'];

          // Handle different response types
          if (responseType == 'note_created' ||
              responseType == 'task_added' ||
              responseType == 'meeting_scheduled') {
            // Success message for created items
            messages.add({
              'type': 'ai',
              'message': reply,
              'timestamp': _getCurrentTime(),
              'showSuggestions': true,
            });
          } else if (responseType == 'meetings_data' ||
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
          } else if (responseType == 'dashboard_data') {
            messages.add({
              'type': 'dashboard_data',
              'message': reply,
              'data': responseData,
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
      debugPrint('Timeout error');
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
      debugPrint('Error: $e');
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
      'Materials': 'show concrete status',
      'Material Status': 'show concrete status',
      'Team': 'show team members',
      'Meetings': 'show upcoming meetings',
      'Tasks': 'show pending tasks',
      'Notes': 'show all notes',
      'Create Note': 'create a note',
      'Create Task': 'create a task',
      'Schedule Meeting': 'schedule a meeting',
      'Dashboard Summary': 'dashboard summary',
    };

    final query = queryMap[action] ?? action;
    sendMessage(query);
  }

  Widget _dashboardRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
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
                            LucideIcons.menu,
                            color: Colors.grey.shade700,
                          ),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    "BuildAssist",
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
                  } else if (msg['type'] == 'ai_delivery' ||
                      msg['type'] == 'procurement_data') {
                    // Show procurement data with AI message header and cards
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show the reply text first
                        AIMessage(
                          message: msg['message'] ?? 'Procurement data:',
                          timestamp: msg['timestamp'],
                          showSuggestions: false,
                          onSuggestionTap: handleQuickAction,
                        ),
                        const SizedBox(height: 12),
                        // Show each procurement item as a card
                        if (msg['data'] is List &&
                            (msg['data'] as List).isNotEmpty)
                          ...(msg['data'] as List).map(
                            (item) => Column(
                              children: [
                                DeliveryCard(
                                  data: Map<String, dynamic>.from(
                                    item is Map
                                        ? item
                                        : {'material': item.toString()},
                                  ),
                                  type: 'procurement',
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          )
                        else if (msg['data'] != null && msg['data'] is Map)
                          Column(
                            children: [
                              DeliveryCard(
                                data: Map<String, dynamic>.from(msg['data']),
                                type: 'procurement',
                              ),
                              const SizedBox(height: 12),
                            ],
                          )
                        else
                          // No data found
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B1E29),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF374151),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF374151),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    LucideIcons.info,
                                    color: Color(0xFF9CA3AF),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'No procurement updates found.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
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
                          ...(msg['data'] as List).map(
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
                  } else if (msg['type'] == 'dashboard_data') {
                    final d = msg['data'] as Map<String, dynamic>? ?? {};
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F7FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.layoutDashboard,
                                    size: 20,
                                    color: const Color(0xFF2563EB),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Project Dashboard',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _dashboardRow(
                                LucideIcons.calendar,
                                'Meetings',
                                '${d['meetings'] ?? 0}',
                                const Color(0xFF2563EB),
                              ),
                              _dashboardRow(
                                LucideIcons.clock,
                                'Pending Tasks',
                                '${d['pendingTasks'] ?? 0}',
                                const Color(0xFFF59E0B),
                              ),
                              _dashboardRow(
                                LucideIcons.checkCircle2,
                                'Completed Tasks',
                                '${d['completedTasks'] ?? 0}',
                                const Color(0xFF10B981),
                              ),
                              _dashboardRow(
                                LucideIcons.stickyNote,
                                'Notes',
                                '${d['notes'] ?? 0}',
                                const Color(0xFF8B5CF6),
                              ),
                              _dashboardRow(
                                LucideIcons.clipboardList,
                                'Total Tasks',
                                '${d['totalTasks'] ?? 0}',
                                const Color(0xFF64748B),
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
                      _buildQuickAction("Schedule Update"),
                      _buildQuickAction("Material Status"),
                      _buildQuickAction("Create Note"),
                      _buildQuickAction("Create Task"),
                      _buildQuickAction("Schedule Meeting"),
                      _buildQuickAction("Dashboard Summary"),
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
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(text, style: const TextStyle(fontSize: 13)),
        ),
      ),
    );
  }
}
