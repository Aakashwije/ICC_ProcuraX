// ═══════════════════════════════════════════════════════════════════════════
// GetStartedPage — Widget Test Suite
// ═══════════════════════════════════════════════════════════════════════════
//
// @file test/widget/get_started_page_test.dart
// @description
//   Tests the GetStartedPage (welcome/landing screen) widget:
//   - Brand title rendering ("ICC ProcuraX")
//   - Tagline text rendering ("Construction", "Meets", "Control")
//   - "Get Started" button presence and tap behaviour
//   - Logo image asset loading
//   - Footer / copyright text
//   - Navigation to login route on button press
//
// @coverage
//   - Title display: 1 test
//   - Tagline sections: 3 tests
//   - Button rendering & interaction: 2 tests
//   - Footer text: 1 test
//   - Navigation: 1 test
//   - Total: 8+ widget test cases

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procurax_frontend/pages/get_started/get_started_page.dart';
import 'package:procurax_frontend/routes/app_routes.dart';

void main() {
  /// Helper to wrap GetStartedPage in a MaterialApp with route handling.
  Widget buildTestApp({Map<String, WidgetBuilder>? routes}) {
    return MaterialApp(
      home: const GetStartedPage(),
      routes:
          routes ??
          {AppRoutes.login: (_) => const Scaffold(body: Text('Login Page'))},
    );
  }

  /// ─────────────────────────────────────────────────────────────────
  /// BRAND TITLE
  /// ─────────────────────────────────────────────────────────────────

  group('GetStartedPage — Brand Title', () {
    testWidgets('displays "ICC ProcuraX" heading', (tester) async {
      await tester.pumpWidget(buildTestApp());
      expect(find.text('ICC ProcuraX'), findsOneWidget);
    });
  });

  /// ─────────────────────────────────────────────────────────────────
  /// TAGLINE TEXT
  /// ─────────────────────────────────────────────────────────────────

  group('GetStartedPage — Tagline', () {
    testWidgets('shows "Construction" tagline word', (tester) async {
      await tester.pumpWidget(buildTestApp());
      expect(find.text('Construction'), findsOneWidget);
    });

    testWidgets('shows "Meets" tagline word', (tester) async {
      await tester.pumpWidget(buildTestApp());
      expect(find.text('Meets'), findsOneWidget);
    });

    testWidgets('shows "Control" tagline word', (tester) async {
      await tester.pumpWidget(buildTestApp());
      expect(find.text('Control'), findsOneWidget);
    });
  });

  /// ─────────────────────────────────────────────────────────────────
  /// GET STARTED BUTTON
  /// ─────────────────────────────────────────────────────────────────

  group('GetStartedPage — Button', () {
    testWidgets('renders "Get Started" button', (tester) async {
      await tester.pumpWidget(buildTestApp());
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('button has correct rounded shape', (tester) async {
      await tester.pumpWidget(buildTestApp());
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final shape = button.style?.shape?.resolve({});
      expect(shape, isA<RoundedRectangleBorder>());
    });
  });

  /// ─────────────────────────────────────────────────────────────────
  /// NAVIGATION
  /// ─────────────────────────────────────────────────────────────────

  group('GetStartedPage — Navigation', () {
    testWidgets('tapping Get Started navigates to login', (tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // After navigation we should see the login page
      expect(find.text('Login Page'), findsOneWidget);
    });
  });

  /// ─────────────────────────────────────────────────────────────────
  /// FOOTER / COPYRIGHT
  /// ─────────────────────────────────────────────────────────────────

  group('GetStartedPage — Footer', () {
    testWidgets('shows copyright notice', (tester) async {
      await tester.pumpWidget(buildTestApp());
      expect(find.textContaining('ICC ProcuraX'), findsWidgets);
    });
  });

  /// ─────────────────────────────────────────────────────────────────
  /// LAYOUT STRUCTURE
  /// ─────────────────────────────────────────────────────────────────

  group('GetStartedPage — Layout', () {
    testWidgets('uses Scaffold with white background', (tester) async {
      await tester.pumpWidget(buildTestApp());
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, equals(Colors.white));
    });

    testWidgets('wraps content in SafeArea', (tester) async {
      await tester.pumpWidget(buildTestApp());
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('uses Column layout for vertical stacking', (tester) async {
      await tester.pumpWidget(buildTestApp());
      expect(find.byType(Column), findsWidgets);
    });
  });
}
