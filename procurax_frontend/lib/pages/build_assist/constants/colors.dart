import 'package:procurax_frontend/theme/app_theme.dart' as theme;

/// Build Assist color constants — delegates to the centralized design system.
/// Kept as `AppColors` to avoid breaking existing imports in build_assist.
// ignore: camel_case_types
class AppColors {
  static const primaryBlue = theme.AppColors.primary;
  static const scaffoldBg = theme.AppColors.surface;
  static const lightGrey = theme.AppColors.neutral100;
  static const warningBg = theme.AppColors.warningLight;
}
