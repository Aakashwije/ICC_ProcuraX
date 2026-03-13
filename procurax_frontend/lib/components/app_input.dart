import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A unified text input field with consistent styling.
///
/// ```dart
/// AppInput(
///   label: 'Email',
///   hint: 'Enter your email',
///   controller: _emailController,
///   prefixIcon: Icons.email,
///   validator: (v) => v!.isEmpty ? 'Required' : null,
/// )
/// ```
class AppInput extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final String? semanticLabel;

  const AppInput({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.focusNode,
    this.textInputAction,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? label,
      textField: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(label!, style: AppTextStyles.labelMedium),
            const SizedBox(height: 6),
          ],
          TextFormField(
            controller: controller,
            validator: validator,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLines: maxLines,
            readOnly: readOnly,
            onTap: onTap,
            onChanged: onChanged,
            focusNode: focusNode,
            textInputAction: textInputAction,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral900,
            ),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
              suffixIcon: suffix,
            ),
          ),
        ],
      ),
    );
  }
}
