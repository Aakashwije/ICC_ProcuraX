import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/ai_message.dart';
import '../widgets/user_message.dart';
import '../widgets/delivery_card.dart';
import '../widgets/bottom_input.dart';
import 'package:procurax_frontend/widgets/app_drawer.dart';
import 'package:procurax_frontend/routes/app_routes.dart';
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
      // Add timeout to prevent hanging
      final response = await http
          .post(
            Uri.parse('http://192.168.8.131:5002/api/buildassist'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': userMessage}),
          )
          .timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Received data: $data');

        setState(() {
          if (data['data'] != null) {
            // Add the AI reply text first
            if (data['reply'] != null) {
              messages.add({
                'type': 'ai',
                'message': data['reply'],
                'timestamp': _getCurrentTime(),
                'showSuggestions': false,
              });
            }

            // Then add the delivery data
            if (data['data'] is List) {
              final items = data['data'] as List;
              for (var item in items) {
                messages.add({
                  'type': 'ai_delivery',
                  'data': item,
                  'timestamp': _getCurrentTime(),
                });
              }
            } else {
              messages.add({
                'type': 'ai_delivery',
                'data': data['data'],
                'timestamp': _getCurrentTime(),
              });
            }
          } else {
            messages.add({
              'type': 'ai',
              'message': data['reply'] ?? 'No reply',
              'timestamp': _getCurrentTime(),
              'showSuggestions': true,
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
    sendMessage(action);
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Builder(
                      builder: (context) => IconButton(
                        icon: Icon(Icons.menu, color: Colors.grey.shade700),
                        onPressed: () => Scaffold.of(context).openDrawer(),
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
                  } else if (msg['type'] == 'ai_delivery') {
                    return Column(
                      children: [
                        DeliveryCard(data: msg['data']),
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
                      _buildQuickAction("Progress Report"),
                      _buildQuickAction("Team"),
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
