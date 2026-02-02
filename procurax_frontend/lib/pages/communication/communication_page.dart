import 'package:flutter/material.dart';
import 'screens/chat_list/chat_list.dart';

class CommunicationPage extends StatelessWidget {
  const CommunicationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChatListScreen(showDrawer: true);
  }
}
