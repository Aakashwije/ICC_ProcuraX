import 'package:flutter/material.dart';
import '../../core/colors.dart';

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColours.background,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.call_outlined, size: 42, color: AppColours.primary),
          SizedBox(height: 12),
          Text(
            'No calls yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColours.primary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Your recent calls will appear here.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
