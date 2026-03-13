import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A standardized confirmation dialog with consistent styling.
///
/// ```dart
/// final confirmed = await ConfirmDialog.show(
///   context,
///   title: 'Delete Note?',
///   message: 'This action cannot be undone.',
///   confirmLabel: 'Delete',
///   isDanger: true,
/// );
/// ```
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final bool isDanger;
  final bool isLoading;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.icon = Icons.info_outline,
    this.isDanger = false,
    this.isLoading = false,
  });

  /// Show the dialog and return true if confirmed.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    IconData icon = Icons.info_outline,
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
        isDanger: isDanger,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = isDanger ? AppColors.error : AppColors.primary;
    final bgColor = isDanger ? AppColors.errorLight : AppColors.primaryLight;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.dialogRadius),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: accentColor),
            ),
            AppSpacing.verticalLg,
            Text(title, style: AppTextStyles.h2, textAlign: TextAlign.center),
            AppSpacing.verticalSm,
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalLg,
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(cancelLabel),
                  ),
                ),
                AppSpacing.horizontalMd,
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: isDanger
                        ? ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                          )
                        : null,
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
