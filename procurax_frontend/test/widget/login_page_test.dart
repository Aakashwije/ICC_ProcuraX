// ═══════════════════════════════════════════════════════════════════════════
// LoginPage — Widget Test Suite
// ═══════════════════════════════════════════════════════════════════════════
//
// @file test/widget/login_page_test.dart
// @description
//   Tests the LoginPage widget covering:
//   - Title and subtitle rendering
//   - Email / Password form fields
//   - Form validation (empty, invalid email)
//   - Password visibility toggle
//   - Remember-me checkbox
//   - Forgot Password link
//   - Sign-in button presence
//   - Create Account link
//
// @coverage
//   - UI elements: 6 tests
//   - Form validation: 4 tests
//   - Interaction: 3 tests
//   - Total: 13+ widget test cases

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procurax_frontend/pages/log_in/login_page.dart';
import 'package:procurax_frontend/routes/app_routes.dart';

void main() {
  /// Helper to wrap LoginPage in a MaterialApp with necessary routes.
  Widget buildTestApp() {
    return MaterialApp(
      home: const LoginPage(),
      routes: {
        AppRoutes.dashboard: (_) =>
            const Scaffold(body: Text('Dashboard Page')),
        AppRoutes.forgotPassword: (_) =>
            const Scaffold(body: Text('Forgot Password Page')),
        AppRoutes.createAccount: (_) =>
            const Scaffold(body: Text('Create Account Page')),
      },
    );
  }

  /// ─────────────────────────────────────────────────────────────────
  /// UI ELEMENTS
  /// ─────────────────────────────────────────────────────────────────

  group('LoginPage — UI Elements', () {
    testWidgets('shows "Login Here" title', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.text('Login Here'), findsOneWidget);
    });

    testWidgets('shows subtitle text', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.textContaining('Building Efficiency'), findsOneWidget);
    });

    testWidgets('renders email text field with hint', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('renders password text field with hint', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('shows "Log in" button', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.text('Log in'), findsOneWidget);
    });

    testWidgets('shows "Remember me" checkbox', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.text('Remember me'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });
  });

  /// ─────────────────────────────────────────────────────────────────
  /// FORM VALIDATION
  /// ─────────────────────────────────────────────────────────────────

  group('LoginPage — Form Validation', () {
    testWidgets('shows error when email is empty on submit', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Tap login without entering any data
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter email'), findsOneWidget);
    });

    testWidgets('shows error when email missing @', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField).first, 'invalidemail');
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter valid email'), findsOneWidget);
    });

    testWidgets('shows error when password is empty', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Enter valid email but no password
      await tester.enterText(find.byType(TextFormField).first, 'user@test.com');
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter password'), findsOneWidget);
    });

    testWidgets('no validation errors when form is filled', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Fill both fields
      await tester.enterText(find.byType(TextFormField).first, 'user@test.com');
      await tester.enterText(find.byType(TextFormField).last, 'securePass123');
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      // Validation errors should NOT appear
      expect(find.text('Enter email'), findsNothing);
      expect(find.text('Enter valid email'), findsNothing);
      expect(find.text('Enter password'), findsNothing);
    });
  });

  /// ─────────────────────────────────────────────────────────────────
  /// INTERACTIONS
  /// ─────────────────────────────────────────────────────────────────

  group('LoginPage — Interactions', () {
    testWidgets('password visibility toggle works', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Initially password is obscured — visibility_off icon shown
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      // Tap the toggle
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      // Now should show visibility icon (not off)
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('forgot password link navigates', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Forgot your password?'), findsOneWidget);
      await tester.tap(find.text('Forgot your password?'));
      await tester.pumpAndSettle();

      expect(find.text('Forgot Password Page'), findsOneWidget);
    });

    testWidgets('remember-me checkbox toggles', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue); // default is true

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      final updated = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(updated.value, isFalse);
    });
  });

  /// ─────────────────────────────────────────────────────────────────
  /// LAYOUT
  /// ─────────────────────────────────────────────────────────────────

  group('LoginPage — Layout', () {
    testWidgets('uses Scaffold with white background', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, equals(Colors.white));
    });

    testWidgets('wraps in Form for validation', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('uses SingleChildScrollView for small screens', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
