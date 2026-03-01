import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'suggestion_chip.dart';

/// AI Message Bubble
class AIMessage extends StatelessWidget {
  const AIMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// AI Avatar
        CircleAvatar(
          backgroundColor: AppColors.primaryBlue,
          child: const Text("AI", style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 10),

        /// Message Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Hello! I'm your BuildAssist AI.\nHow can I help you with your construction project today?",
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 14),

                    /// Suggestion Chips
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: const [
                        SuggestionChip(label: "Schedule"),
                        SuggestionChip(label: "Materials"),
                        SuggestionChip(label: "Progress"),
                        SuggestionChip(label: "Team"),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              /// Timestamp
              const Text(
                "09:30 AM",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
