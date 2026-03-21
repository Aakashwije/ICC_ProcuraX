// ═══════════════════════════════════════════════════════════════════════════
// ProcurementView — Unit Test Suite
// ═══════════════════════════════════════════════════════════════════════════
//
// @file test/unit/procurement_view_test.dart
// @description
//   Tests the ProcurementView, ProcurementItemView, and DeliverySimpleView
//   aggregated models used by the procurement page:
//   - ProcurementView.fromJson with nested items and deliveries
//   - ProcurementItemView.fromJson with all logistics fields
//   - DeliverySimpleView.fromJson with delivery schedule data
//   - Null safety and default value handling
//   - Empty collection handling
//
// @coverage
//   - ProcurementView: 4 tests
//   - ProcurementItemView: 4 tests
//   - DeliverySimpleView: 3 tests
//   - Edge cases: 3 tests
//   - Total: 14 test cases

import 'package:flutter_test/flutter_test.dart';
import 'package:procurax_frontend/models/procurement_view.dart';

void main() {
  /// ─────────────────────────────────────────────────────────────────
  /// PROCUREMENT VIEW (AGGREGATED MODEL)
  /// ─────────────────────────────────────────────────────────────────

  group('ProcurementView', () {
    test('fromJson parses complete nested structure', () {
      final json = {
        'procurementItems': [
          {
            'materialList': 'Steel Beams',
            'responsibility': 'Supplier A',
            'openingLC': '2025-01-01',
            'etd': '2025-02-01',
            'eta': '2025-03-01',
            'boiApproval': '2025-01-15',
            'revisedDeliveryToSite': '2025-04-01',
            'requiredDateCMS': '2025-04-05',
            'status': 'On Time',
          },
          {
            'materialList': 'Concrete Mix',
            'responsibility': 'Supplier B',
            'openingLC': '2025-02-01',
            'etd': '2025-03-01',
            'eta': '2025-04-01',
            'boiApproval': '2025-02-15',
            'revisedDeliveryToSite': '2025-05-01',
            'requiredDateCMS': '2025-05-05',
            'status': 'Delayed',
          },
        ],
        'upcomingDeliveries': [
          {
            'materialList': 'Rebar',
            'revisedDeliveryToSite': '2025-06-15',
            'status': 'Early',
          },
        ],
      };

      final view = ProcurementView.fromJson(json);
      expect(view.procurementItems.length, 2);
      expect(view.upcomingDeliveries.length, 1);
      expect(view.procurementItems[0].materialList, 'Steel Beams');
      expect(view.upcomingDeliveries[0].materialList, 'Rebar');
    });

    test('fromJson handles empty lists', () {
      final json = {'procurementItems': [], 'upcomingDeliveries': []};

      final view = ProcurementView.fromJson(json);
      expect(view.procurementItems, isEmpty);
      expect(view.upcomingDeliveries, isEmpty);
    });

    test('fromJson defaults missing lists to empty', () {
      final view = ProcurementView.fromJson({});
      expect(view.procurementItems, isEmpty);
      expect(view.upcomingDeliveries, isEmpty);
    });

    test('fromJson handles null lists', () {
      final json = {'procurementItems': null, 'upcomingDeliveries': null};

      final view = ProcurementView.fromJson(json);
      expect(view.procurementItems, isEmpty);
      expect(view.upcomingDeliveries, isEmpty);
    });
  });

  /// ─────────────────────────────────────────────────────────────────
  /// PROCUREMENT ITEM VIEW
  /// ─────────────────────────────────────────────────────────────────

  group('ProcurementItemView', () {
    test('fromJson parses all logistics fields', () {
      final json = {
        'materialList': 'Electrical Cables',
        'responsibility': 'ElectriCo',
        'openingLC': '2025-03-10',
        'etd': '2025-04-10',
        'eta': '2025-05-10',
        'boiApproval': '2025-03-20',
        'revisedDeliveryToSite': '2025-06-01',
        'requiredDateCMS': '2025-06-15',
        'status': 'On Time',
      };

      final item = ProcurementItemView.fromJson(json);
      expect(item.materialList, 'Electrical Cables');
      expect(item.responsibility, 'ElectriCo');
      expect(item.openingLC, '2025-03-10');
      expect(item.etd, '2025-04-10');
      expect(item.eta, '2025-05-10');
      expect(item.boiApproval, '2025-03-20');
      expect(item.revisedDeliveryToSite, '2025-06-01');
      expect(item.requiredDateCMS, '2025-06-15');
      expect(item.status, 'On Time');
    });

    test('fromJson converts null values to empty strings', () {
      final item = ProcurementItemView.fromJson({});
      expect(item.materialList, '');
      expect(item.responsibility, '');
      expect(item.openingLC, '');
      expect(item.etd, '');
      expect(item.eta, '');
      expect(item.status, isNull);
    });

    test('fromJson handles numeric values as strings', () {
      final json = {
        'materialList': 12345,
        'responsibility': true,
        'openingLC': null,
        'etd': '',
        'eta': 'N/A',
        'boiApproval': '',
        'revisedDeliveryToSite': '',
        'requiredDateCMS': '',
      };

      final item = ProcurementItemView.fromJson(json);
      expect(item.materialList, '12345');
      expect(item.responsibility, 'true');
      expect(item.openingLC, '');
      expect(item.eta, 'N/A');
    });

    test('status is optional and nullable', () {
      final withStatus = ProcurementItemView.fromJson({
        'materialList': 'X',
        'responsibility': 'Y',
        'openingLC': '',
        'etd': '',
        'eta': '',
        'boiApproval': '',
        'revisedDeliveryToSite': '',
        'requiredDateCMS': '',
        'status': 'Delayed',
      });
      expect(withStatus.status, 'Delayed');

      final withoutStatus = ProcurementItemView.fromJson({
        'materialList': 'X',
        'responsibility': 'Y',
        'openingLC': '',
        'etd': '',
        'eta': '',
        'boiApproval': '',
        'revisedDeliveryToSite': '',
        'requiredDateCMS': '',
      });
      expect(withoutStatus.status, isNull);
    });
  });

  /// ─────────────────────────────────────────────────────────────────
  /// DELIVERY SIMPLE VIEW
  /// ─────────────────────────────────────────────────────────────────

  group('DeliverySimpleView', () {
    test('fromJson parses delivery fields', () {
      final json = {
        'materialList': 'Plumbing Fixtures',
        'revisedDeliveryToSite': '2025-08-20',
        'status': 'Early',
      };

      final delivery = DeliverySimpleView.fromJson(json);
      expect(delivery.materialList, 'Plumbing Fixtures');
      expect(delivery.revisedDeliveryToSite, '2025-08-20');
      expect(delivery.status, 'Early');
    });

    test('fromJson handles missing fields', () {
      final delivery = DeliverySimpleView.fromJson({});
      expect(delivery.materialList, '');
      expect(delivery.revisedDeliveryToSite, '');
      expect(delivery.status, isNull);
    });

    test('fromJson converts types to string', () {
      final json = {
        'materialList': 999,
        'revisedDeliveryToSite': false,
        'status': 42,
      };

      final delivery = DeliverySimpleView.fromJson(json);
      expect(delivery.materialList, '999');
      expect(delivery.revisedDeliveryToSite, 'false');
      expect(delivery.status, '42');
    });
  });

  /// ─────────────────────────────────────────────────────────────────
  /// EDGE CASES
  /// ─────────────────────────────────────────────────────────────────

  group('Procurement Models — Edge Cases', () {
    test('ProcurementView with many items', () {
      final items = List.generate(
        100,
        (i) => {
          'materialList': 'Item $i',
          'responsibility': 'Supplier $i',
          'openingLC': '',
          'etd': '',
          'eta': '',
          'boiApproval': '',
          'revisedDeliveryToSite': '',
          'requiredDateCMS': '',
        },
      );

      final view = ProcurementView.fromJson({
        'procurementItems': items,
        'upcomingDeliveries': [],
      });

      expect(view.procurementItems.length, 100);
      expect(view.procurementItems[50].materialList, 'Item 50');
    });

    test('handles unicode in material names', () {
      final json = {
        'materialList': '鋼材 — Steel 🏗️',
        'responsibility': 'サプライヤー A',
        'openingLC': '',
        'etd': '',
        'eta': '',
        'boiApproval': '',
        'revisedDeliveryToSite': '',
        'requiredDateCMS': '',
        'status': '早い',
      };

      final item = ProcurementItemView.fromJson(json);
      expect(item.materialList, contains('Steel'));
      expect(item.responsibility, contains('サプライヤー'));
      expect(item.status, '早い');
    });

    test('handles very long field values', () {
      final longString = 'A' * 10000;
      final json = {
        'materialList': longString,
        'responsibility': '',
        'openingLC': '',
        'etd': '',
        'eta': '',
        'boiApproval': '',
        'revisedDeliveryToSite': '',
        'requiredDateCMS': '',
      };

      final item = ProcurementItemView.fromJson(json);
      expect(item.materialList.length, 10000);
    });
  });
}
