import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Custom Suggestion Chip (Web-style)
class SuggestionChip extends StatelessWidget {
  final String label;

  const SuggestionChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}
