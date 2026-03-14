/// ═══════════════════════════════════════════════════════════════════════════
/// Theme Notifier — Unit Test Suite (Dart/Flutter)
/// ═══════════════════════════════════════════════════════════════════════════
///
/// @file test/settings/theme_notifier_test.dart
/// @description
///   Tests the ThemeNotifier provider for theme management:
///   - Theme mode state management (Light, Dark, System)
///   - setTheme method for theme switching
///   - Default theme initialisation
///   - Listener notification for state changes
///   - Graceful fallback for unknown theme values
///
/// @coverage
///   - Default state: 1 test (light theme by default)
///   - setTheme("Dark"): 1 test (switches to dark mode)
///   - setTheme("Light"): 1 test (switches to light mode)
///   - Unknown theme values: 1 test (fallback to light)
///   - Listener notification: 2 test (state change callbacks)
///
/// @provider_pattern
///   - Uses ChangeNotifier for state management
///   - Listeners notified on setTheme() calls
///   - Immutable theme mode enum
///
/// @ui_integration
///   - Material Design theme switching
///   - Respects Flutter's ThemeMode
///   - Compatible with MaterialApp(themeMode)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procurax_frontend/pages/settings/theme_notifier.dart';

void main() {
  /// ─────────────────────────────────────────────────────────────────
  /// THEME NOTIFIER STATE TESTS
  /// ─────────────────────────────────────────────────────────────────
  /// Test theme management and state switching.

  group('ThemeNotifier', () {
    late ThemeNotifier notifier;

    /// Setup fresh notifier instance before each test
    setUp(() {
      notifier = ThemeNotifier();
    });

    test('defaults to light theme', () {
      expect(notifier.themeMode, equals(ThemeMode.light));
    });

    test('setTheme("Dark") switches to dark mode', () {
      notifier.setTheme('Dark');
      expect(notifier.themeMode, equals(ThemeMode.dark));
    });

    test('setTheme("Light") stays in / returns to light mode', () {
      notifier.setTheme('Dark');
      notifier.setTheme('Light');
      expect(notifier.themeMode, equals(ThemeMode.light));
    });

    /// Tests fallback behaviour for unknown theme names
    /// Ensures graceful degradation if settings contain invalid values
    test('setTheme with any non-"Dark" string resolves to light', () {
      notifier.setTheme('Random');
      expect(notifier.themeMode, equals(ThemeMode.light));

      notifier.setTheme('');
      expect(notifier.themeMode, equals(ThemeMode.light));

      notifier.setTheme('dark'); // lowercase
      expect(notifier.themeMode, equals(ThemeMode.light));
    });

    test('notifies listeners on theme change', () {
      int callCount = 0;
      notifier.addListener(() => callCount++);

      notifier.setTheme('Dark');
      expect(callCount, equals(1));

      notifier.setTheme('Light');
      expect(callCount, equals(2));
    });

    test('notifies even when setting same theme', () {
      int callCount = 0;
      notifier.addListener(() => callCount++);

      notifier.setTheme('Light');
      expect(callCount, equals(1));
    });
  });
}
