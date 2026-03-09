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

/// ===============================================================
/// Main Chat Screen
/// ===============================================================
class BuildAssistPage extends StatefulWidget {
  const BuildAssistPage({super.key});

  @override
  State<BuildAssistPage> createState() => _BuildAssistPageState();
}

class _BuildAssistPageState extends State<BuildAssistPage> {
  final List<Map<String, dynamic>> messages = [];
  final TextEditingController _messageController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add initial AI message
    messages.add({
      'type': 'ai',
      'message':
          "Hello! I'm your BuildAssist AI.\nHow can I help you with your construction project today?",
      'timestamp': '09:30 AM',
      'showSuggestions': true,
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

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/chatbot'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': userMessage}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          if (data['type'] == 'procurement_data' && data['data'] != null) {
            // Handle structured procurement data
            for (var record in data['data']) {
              messages.add({
                'type': 'ai_delivery',
                'data': record,
                'timestamp': _getCurrentTime(),
              });
            }
          } else {
            // Regular AI message
            messages.add({
              'type': 'ai',
              'message': data['reply'],
              'timestamp': _getCurrentTime(),
              'showSuggestions': false,
            });
          }
          isLoading = false;
        });
      } else {
        throw Exception('Failed to get response');
      }
    } catch (e) {
      setState(() {
        messages.add({
          'type': 'ai',
          'message':
              'Sorry, I\'m having trouble connecting right now. Please try again.',
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
            /// ===================================================
            /// CUSTOM HEADER (App Bar)
            /// ===================================================
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      //App Title
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
                ],
              ),
            ),

            /// ===================================================
            /// CHAT AREA
            /// ===================================================
            Expanded(
              child: ListView.builder(
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

            /// ===================================================
            /// QUICK ACTION BUTTONS
            /// ===================================================
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
                      bottomAction(
                        "Schedule Update",
                        () => handleQuickAction("Schedule Update"),
                      ),
                      bottomAction(
                        "Material Status",
                        () => handleQuickAction("Material Status"),
                      ),
                      bottomAction(
                        "Progress Report",
                        () => handleQuickAction("Progress Report"),
                      ),
                      bottomAction("Team", () => handleQuickAction("Team")),
                    ],
                  ),
                ),
              ),

            /// ===================================================
            /// BOTTOM MESSAGE INPUT
            /// ===================================================
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

  Widget bottomAction(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
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
