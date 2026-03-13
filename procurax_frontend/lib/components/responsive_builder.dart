import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A responsive layout builder that adapts to mobile / tablet / desktop.
///
/// ```dart
/// ResponsiveBuilder(
///   mobile: MobileLayout(),
///   tablet: TabletLayout(),   // optional — falls back to mobile
///   desktop: DesktopLayout(), // optional — falls back to tablet
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppBreakpoints.tablet) {
          return desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= AppBreakpoints.mobile) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}

/// A responsive grid that adapts column count to screen width.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileCols;
  final int tabletCols;
  final int desktopCols;
  final double spacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileCols = 1,
    this.tabletCols = 2,
    this.desktopCols = 3,
    this.spacing = AppSpacing.md,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int cols;
        if (constraints.maxWidth >= AppBreakpoints.tablet) {
          cols = desktopCols;
        } else if (constraints.maxWidth >= AppBreakpoints.mobile) {
          cols = tabletCols;
        } else {
          cols = mobileCols;
        }

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children.map((child) {
            final width =
                (constraints.maxWidth - (spacing * (cols - 1))) / cols;
            return SizedBox(width: width, child: child);
          }).toList(),
        );
      },
    );
  }
}

/// Responsive padding that adapts to screen size.
class ResponsivePadding extends StatelessWidget {
  final Widget child;

  const ResponsivePadding({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double horizontal;
    if (width >= AppBreakpoints.tablet) {
      horizontal = 48;
    } else if (width >= AppBreakpoints.mobile) {
      horizontal = 32;
    } else {
      horizontal = 20;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 16),
      child: child,
    );
  }
}
