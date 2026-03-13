import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A standardized loading state widget with skeleton or spinner.
///
/// ```dart
/// LoadingState(message: 'Loading tasks...')
/// ```
class LoadingState extends StatelessWidget {
  final String? message;
  final bool fullScreen;

  const LoadingState({super.key, this.message, this.fullScreen = true});

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        if (message != null) ...[
          AppSpacing.verticalMd,
          Text(
            message!,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (fullScreen) {
      return Center(child: content);
    }

    return Padding(padding: AppSpacing.pagePadding, child: content);
  }
}

/// A small inline loading indicator
class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  const LoadingIndicator({super.key, this.size = 20, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation(
          color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
