import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A unified card component with consistent styling.
///
/// ```dart
/// AppCard(
///   child: Text('Content'),
///   onTap: () {},
///   padding: AppSpacing.cardPadding,
/// )
/// ```
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  final List<BoxShadow>? shadow;
  final String? semanticLabel;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.borderColor,
    this.shadow,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card = AnimatedContainer(
      duration: AppAnimations.fast,
      padding: padding ?? AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: color ?? (isDark ? AppColors.darkCard : AppColors.card),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color:
              borderColor ??
              (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppColors.divider),
        ),
        boxShadow: shadow ?? AppShadows.sm,
      ),
      child: child,
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardRadius,
          child: card,
        ),
      );
    }

    if (semanticLabel != null) {
      card = Semantics(label: semanticLabel, child: card);
    }

    return card;
  }
}

/// A gradient-header card for dashboard stats
class AppStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const AppStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title: $value',
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: AppRadius.cardRadius,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            AppSpacing.horizontalMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelSmall),
                  const SizedBox(height: 2),
                  Text(value, style: AppTextStyles.h2.copyWith(color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
