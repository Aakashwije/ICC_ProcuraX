import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProcuraX Design System — Single Source of Truth
// ─────────────────────────────────────────────────────────────────────────────
// Import this file everywhere:
//   import 'package:procurax_frontend/theme/app_theme.dart';
//
// Usage:
//   AppColors.primary          — unified primary blue
//   AppTextStyles.heading      — pre-built text styles
//   AppSpacing.md              — spacing tokens
//   AppRadius.card             — border-radius tokens
//   AppShadows.card            — elevation shadows
//   AppTheme.lightTheme        — MaterialApp theme
// ─────────────────────────────────────────────────────────────────────────────

/// Unified color palette — NO hex literals anywhere else in the app.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1F4DF0);
  static const Color primaryLight = Color(0xFFE6EEF8);
  static const Color primaryDark = Color(0xFF1538B0);

  // ── Neutral ────────────────────────────────────────────────────────────
  static const Color neutral900 = Color(0xFF1B1E29);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral50 = Color(0xFFF9FAFB);

  // ── Semantic ───────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ── Surface ────────────────────────────────────────────────────────────
  static const Color scaffold = Colors.white;
  static const Color surface = Color(0xFFF6F7F9);
  static const Color card = Colors.white;
  static const Color divider = Color(0xFFE5E7EB);

  // ── Dark mode overrides ────────────────────────────────────────────────
  static const Color darkScaffold = Color(0xFF111827);
  static const Color darkSurface = Color(0xFF1F2937);
  static const Color darkCard = Color(0xFF1F2937);
}

/// Spacing scale (4-pt grid)
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Standard page padding
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,
  );

  /// Card inner padding
  static const EdgeInsets cardPadding = EdgeInsets.all(16);

  /// Section spacing
  static const SizedBox verticalSm = SizedBox(height: sm);
  static const SizedBox verticalMd = SizedBox(height: md);
  static const SizedBox verticalLg = SizedBox(height: lg);
  static const SizedBox verticalXl = SizedBox(height: xl);

  static const SizedBox horizontalSm = SizedBox(width: sm);
  static const SizedBox horizontalMd = SizedBox(width: md);
}

/// Border-radius tokens
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 100;

  static final BorderRadius cardRadius = BorderRadius.circular(md);
  static final BorderRadius buttonRadius = BorderRadius.circular(md);
  static final BorderRadius inputRadius = BorderRadius.circular(md);
  static final BorderRadius dialogRadius = BorderRadius.circular(xl);
  static final BorderRadius chipRadius = BorderRadius.circular(pill);
}

/// Shadow presets
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get sm => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get dialog => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];
}

/// Pre-built text styles — all use Poppins
class AppTextStyles {
  AppTextStyles._();

  static const String _fontFamily = 'Poppins';

  // ── Display ────────────────────────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w900,
    color: AppColors.neutral900,
    height: 1.2,
  );

  // ── Headings ───────────────────────────────────────────────────────────
  static const TextStyle h1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.neutral900,
    height: 1.3,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral900,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral900,
    height: 1.4,
  );

  // ── Body ───────────────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.neutral700,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.neutral700,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.neutral500,
    height: 1.5,
  );

  // ── Labels ─────────────────────────────────────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral900,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral700,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral500,
  );

  // ── Button ─────────────────────────────────────────────────────────────
  static const TextStyle button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  // ── Caption ────────────────────────────────────────────────────────────
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.neutral500,
  );
}

/// Animation constants
class AppAnimations {
  AppAnimations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 350);

  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve entranceCurve = Curves.easeOut;
  static const Curve exitCurve = Curves.easeIn;
  static const Curve bounceCurve = Curves.elasticOut;
}

/// Responsive breakpoints
class AppBreakpoints {
  AppBreakpoints._();

  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double widescreen = 1440;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= mobile && w < tablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;

  static bool isWidescreen(BuildContext context) =>
      MediaQuery.of(context).size.width >= widescreen;
}

/// Centralized ThemeData builder
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: AppColors.scaffold,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryLight,
      surface: AppColors.surface,
      error: AppColors.error,
      outline: AppColors.neutral300,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        color: AppColors.primary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: AppColors.primary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        textStyle: AppTextStyles.button,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTextStyles.button,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTextStyles.buttonSmall,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.neutral100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: const BorderSide(color: AppColors.neutral300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: const BorderSide(color: AppColors.neutral300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
      labelStyle: AppTextStyles.labelMedium,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardRadius,
        side: const BorderSide(color: AppColors.divider),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.dialogRadius),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.neutral100,
      selectedColor: AppColors.primaryLight,
      labelStyle: AppTextStyles.labelSmall,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.chipRadius),
      side: BorderSide.none,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.neutral900,
        borderRadius: AppRadius.cardRadius,
      ),
      textStyle: AppTextStyles.bodySmall.copyWith(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkScaffold,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryDark,
      surface: AppColors.darkSurface,
      error: AppColors.error,
      outline: AppColors.neutral500,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkScaffold,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        textStyle: AppTextStyles.button,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
        elevation: 0,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardRadius,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Responsive Design System
// ─────────────────────────────────────────────────────────────────────────────

/// Responsive utilities for adaptive layouts
class AppResponsive {
  AppResponsive._();

  /// Check device type
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < AppBreakpoints.mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppBreakpoints.mobile &&
      MediaQuery.of(context).size.width < AppBreakpoints.tablet;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppBreakpoints.tablet;

  static bool isWidescreen(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppBreakpoints.widescreen;

  /// Get current device type
  static DeviceType deviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < AppBreakpoints.mobile) return DeviceType.mobile;
    if (width < AppBreakpoints.tablet) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Responsive page padding - adjusts based on screen size
  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < AppBreakpoints.mobile) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    } else if (width < AppBreakpoints.tablet) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    } else if (width < AppBreakpoints.desktop) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
  }

  /// Responsive horizontal padding only
  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < AppBreakpoints.mobile) return 16;
    if (width < AppBreakpoints.tablet) return 24;
    if (width < AppBreakpoints.desktop) return 32;
    return 48;
  }

  /// Responsive grid column count
  static int gridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < AppBreakpoints.mobile) return 1;
    if (width < AppBreakpoints.tablet) return 2;
    if (width < AppBreakpoints.desktop) return 3;
    return 4;
  }

  /// Responsive card width for grid layouts
  static double cardWidth(BuildContext context, {double spacing = 16}) {
    final width = MediaQuery.of(context).size.width;
    final padding = horizontalPadding(context) * 2;
    final columns = gridColumns(context);
    final totalSpacing = spacing * (columns - 1);
    return (width - padding - totalSpacing) / columns;
  }

  /// Responsive font size multiplier
  static double fontScale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < AppBreakpoints.mobile) return 0.9;
    if (width < AppBreakpoints.tablet) return 1.0;
    return 1.1;
  }

  /// Responsive icon size
  static double iconSize(BuildContext context, {double base = 24}) {
    return base * fontScale(context);
  }

  /// Responsive spacing multiplier
  static double spacingScale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < AppBreakpoints.mobile) return 0.85;
    if (width < AppBreakpoints.tablet) return 1.0;
    return 1.15;
  }

  /// Get responsive value based on device type
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final type = deviceType(context);
    switch (type) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Maximum content width for readability
  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < AppBreakpoints.mobile) return width;
    if (width < AppBreakpoints.tablet) return width;
    if (width < AppBreakpoints.desktop) return 800;
    return 1000;
  }

  /// Constrain content to max width with centering
  static Widget constrainWidth({
    required Widget child,
    required BuildContext context,
    double? maxWidth,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? maxContentWidth(context),
        ),
        child: child,
      ),
    );
  }
}

/// Device type enum for responsive design
enum DeviceType { mobile, tablet, desktop }

/// Responsive builder widget for declarative responsive layouts
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({super.key, required this.builder})
    : mobile = null,
      tablet = null,
      desktop = null;

  const ResponsiveBuilder.fromWidgets({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : builder = _defaultBuilder;

  static Widget _defaultBuilder(BuildContext context, DeviceType type) {
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = AppResponsive.deviceType(context);

    if (mobile != null) {
      switch (deviceType) {
        case DeviceType.mobile:
          return mobile!;
        case DeviceType.tablet:
          return tablet ?? mobile!;
        case DeviceType.desktop:
          return desktop ?? tablet ?? mobile!;
      }
    }

    return builder(context, deviceType);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Accessibility Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Accessibility utilities for proper semantic widgets
class AppAccessibility {
  AppAccessibility._();

  /// Wrap an icon button with tooltip for accessibility
  static Widget iconButtonWithTooltip({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
    double size = 24,
    bool enabled = true,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, color: color, size: size),
        onPressed: enabled ? onPressed : null,
        tooltip: tooltip,
      ),
    );
  }

  /// Semantic label for icon-only widgets
  static Widget semanticIcon({
    required Widget child,
    required String label,
    bool excludeSemantics = false,
  }) {
    return Semantics(
      label: label,
      excludeSemantics: excludeSemantics,
      child: child,
    );
  }

  /// Check if high contrast mode is enabled
  static bool isHighContrast(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// Check if reduced motion is preferred
  static bool prefersReducedMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Get appropriate animation duration based on accessibility settings
  static Duration animationDuration(
    BuildContext context, {
    Duration normal = const Duration(milliseconds: 300),
  }) {
    if (prefersReducedMotion(context)) {
      return Duration.zero;
    }
    return normal;
  }
}
