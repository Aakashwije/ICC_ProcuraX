import 'package:flutter/material.dart';
import 'package:procurax_frontend/theme/app_theme.dart' as theme;

class UserMessage extends StatelessWidget {
  final String message;
  final String timestamp;

  const UserMessage({
    super.key,
    required this.message,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              color: theme.AppColors.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              message,
              style: theme.AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
              ),
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
    );
  }
}
