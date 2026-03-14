import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procurax_frontend/pages/settings/theme_notifier.dart';

void main() {
  group('ThemeNotifier', () {
    late ThemeNotifier notifier;

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
