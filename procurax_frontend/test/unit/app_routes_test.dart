// ═══════════════════════════════════════════════════════════════════════════
// AppRoutes — Unit Test Suite
// ═══════════════════════════════════════════════════════════════════════════
//
// @file test/unit/app_routes_test.dart
// @description
//   Tests the AppRoutes constants class:
//   - All route paths are defined and non-empty
//   - Route naming conventions (leading slash, lowercase)
//   - No duplicate route values
//   - Key routes used across the app exist
//
// @coverage
//   - Route existence: 12 tests (all defined routes)
//   - Format validation: 2 tests
//   - Uniqueness: 1 test
//   - Total: 15 test cases

import 'package:flutter_test/flutter_test.dart';
import 'package:procurax_frontend/routes/app_routes.dart';

void main() {
  /// ─────────────────────────────────────────────────────────────────
  /// ROUTE EXISTENCE
  /// ─────────────────────────────────────────────────────────────────

  group('AppRoutes — Route Definitions', () {
    test('getStarted route is root /', () {
      expect(AppRoutes.getStarted, '/');
    });

    test('login route is defined', () {
      expect(AppRoutes.login, '/login');
    });

    test('createAccount route is defined', () {
      expect(AppRoutes.createAccount, '/create-account');
    });

    test('forgotPassword route is defined', () {
      expect(AppRoutes.forgotPassword, '/forgot-password');
    });

    test('dashboard route is defined', () {
      expect(AppRoutes.dashboard, '/dashboard');
    });

    test('settings route is defined', () {
      expect(AppRoutes.settings, '/settings');
    });

    test('notifications route is defined', () {
      expect(AppRoutes.notifications, '/notifications');
    });

    test('procurement route is defined', () {
      expect(AppRoutes.procurement, '/procurement');
    });

    test('buildAssist route is defined', () {
      expect(AppRoutes.buildAssist, '/build-assist');
    });

    test('tasks route is defined', () {
      expect(AppRoutes.tasks, '/tasks');
    });

    test('notes route is defined', () {
      expect(AppRoutes.notes, '/notes');
    });

    test('communication route is defined', () {
      expect(AppRoutes.communication, '/communication');
    });

    test('meetings route is defined', () {
      expect(AppRoutes.meetings, '/meetings');
    });

    test('documents route is defined', () {
      expect(AppRoutes.documents, '/documents');
    });
  });

  /// ─────────────────────────────────────────────────────────────────
  /// FORMAT VALIDATION
  /// ─────────────────────────────────────────────────────────────────

  group('AppRoutes — Naming Conventions', () {
    final allRoutes = [
      AppRoutes.getStarted,
      AppRoutes.login,
      AppRoutes.createAccount,
      AppRoutes.forgotPassword,
      AppRoutes.dashboard,
      AppRoutes.settings,
      AppRoutes.notifications,
      AppRoutes.procurement,
      AppRoutes.buildAssist,
      AppRoutes.tasks,
      AppRoutes.notes,
      AppRoutes.communication,
      AppRoutes.meetings,
      AppRoutes.documents,
    ];

    test('all routes start with /', () {
      for (final route in allRoutes) {
        expect(
          route.startsWith('/'),
          isTrue,
          reason: 'Route "$route" should start with /',
        );
      }
    });

    test('all routes are lowercase with hyphens only', () {
      final validPattern = RegExp(r'^/[a-z\-]*$');
      for (final route in allRoutes) {
        expect(
          validPattern.hasMatch(route),
          isTrue,
          reason: 'Route "$route" should be lowercase with hyphens',
        );
      }
    });

    test('no duplicate route values exist', () {
      final routeSet = allRoutes.toSet();
      expect(
        routeSet.length,
        allRoutes.length,
        reason: 'Duplicate route paths detected',
      );
    });
  });

  /// ─────────────────────────────────────────────────────────────────
  /// CRITICAL ROUTES
  /// ─────────────────────────────────────────────────────────────────

  group('AppRoutes — Critical Paths', () {
    test('auth flow routes exist (login, create, forgot)', () {
      expect(AppRoutes.login, isNotEmpty);
      expect(AppRoutes.createAccount, isNotEmpty);
      expect(AppRoutes.forgotPassword, isNotEmpty);
    });

    test('main navigation routes exist', () {
      expect(AppRoutes.dashboard, isNotEmpty);
      expect(AppRoutes.tasks, isNotEmpty);
      expect(AppRoutes.notes, isNotEmpty);
      expect(AppRoutes.procurement, isNotEmpty);
    });
  });
}
