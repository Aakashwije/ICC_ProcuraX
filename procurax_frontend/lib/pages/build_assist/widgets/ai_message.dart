import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'suggestion_chip.dart';

class AIMessage extends StatelessWidget {
  final String message;
  final String timestamp;
  final bool showSuggestions;
  final Function(String)? onSuggestionTap;

  const AIMessage({
    super.key,
    required this.message,
    required this.timestamp,
    this.showSuggestions = false,
    this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: AppColors.primaryBlue,
          child: const Text("AI", style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 10),
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
                    Text(message, style: const TextStyle(fontSize: 14)),
                    if (showSuggestions) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          SuggestionChip(
                            label: "Schedule",
                            onTap: () => onSuggestionTap?.call("Schedule"),
                          ),
                          SuggestionChip(
                            label: "Materials",
                            onTap: () => onSuggestionTap?.call("Materials"),
                          ),
                          SuggestionChip(
                            label: "Progress",
                            onTap: () => onSuggestionTap?.call("Progress"),
                          ),
                          SuggestionChip(
                            label: "Team",
                            onTap: () => onSuggestionTap?.call("Team"),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                timestamp,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
