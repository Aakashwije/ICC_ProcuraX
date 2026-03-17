import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'suggestion_chip.dart';
import 'package:procurax_frontend/theme/app_theme.dart' as theme;

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
          child: const Text("BA", style: TextStyle(color: Colors.white)),
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
                  boxShadow: theme.AppShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message, style: theme.AppTextStyles.bodyMedium),
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
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                timestamp,
                style: theme.AppTextStyles.caption.copyWith(
                  color: theme.AppColors.neutral700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
