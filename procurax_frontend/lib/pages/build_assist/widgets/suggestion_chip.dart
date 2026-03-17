import 'package:flutter/material.dart';
import 'package:procurax_frontend/theme/app_theme.dart' as theme;

class SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const SuggestionChip({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: theme.AppSpacing.md,
          vertical: theme.AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: theme.AppColors.neutral100,
          borderRadius: BorderRadius.circular(theme.AppRadius.lg),
        ),
        child: Text(label, style: theme.AppTextStyles.labelSmall),
      ),
    );
  }
}
