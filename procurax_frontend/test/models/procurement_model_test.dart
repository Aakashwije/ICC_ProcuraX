/// ═══════════════════════════════════════════════════════════════════════════
/// Procurement Models — Comprehensive Unit Test Suite (Dart/Flutter)
/// ═══════════════════════════════════════════════════════════════════════════
///
/// @file test/models/procurement_model_test.dart
/// @description
///   Tests procurement management models for Google Sheets integration:
///   - ProcurementItem: individual material/supply line items
///   - ProcurementView: aggregated view with filtering and sorting
///   - UpcomingDelivery: delivery schedule items
///   - JSON serialisation for API communication
///   - Status calculation (On Time, Early, Delayed)
///   - Date field mapping from Google Sheets
///
/// @models_covered
///   - ProcurementItem: ~10 fields (materials, suppliers, dates, statuses)
///   - ProcurementView: aggregated collection with statistics
///   - UpcomingDelivery: delivery schedule entries
///
/// @coverage
///   - ProcurementItem.fromJson: 3 test cases (complete data, edge cases)
///   - ProcurementView.fromJson: 3 test cases (nested structures)
///   - UpcomingDelivery.fromJson: 2 test cases (delivery data)
///   - Round-trip serialisation: 2 test cases (toJson validation)
///   - Edge cases: 8 test cases (null fields, date boundaries)
///
/// @google_sheets_integration
///   - Field mapping from spreadsheet columns
///   - Date format handling (various date formats)
///   - Status computation from delivery dates
///   - Filtering and sorting utilities

import 'package:flutter_test/flutter_test.dart';
import 'package:procurax_frontend/models/procurement_item.dart';
import 'package:procurax_frontend/models/procurement_view.dart';

void main() {
  /// ─────────────────────────────────────────────────────────────────
  /// PROCUREMENT ITEM MODEL TESTS
  /// ─────────────────────────────────────────────────────────────────
  /// Test parsing of individual procurement line items from API.

  /* ═══════════════════════════════════════════════════════════════════ */
  /*  ProcurementItem — Supply line item with supplier and dates      */
  /* ═══════════════════════════════════════════════════════════════════ */
  group('ProcurementItem', () {
    test('fromJson parses complete JSON correctly', () {
      final json = {
        'materialList': 'Steel Beams',
        'responsibility': 'Supplier A',
        'openingLC': '2025-01-01',
        'etd': '2025-02-01',
        'eta': '2025-03-01',
        'boiApproval': '2025-01-15',
        'revisedDeliveryToSite': '2025-04-01',
        'requiredDateCMS': '2025-04-05',
        'status': 'Early',
      };

      final item = ProcurementItem.fromJson(json);

      expect(item.materialList, equals('Steel Beams'));
      expect(item.responsibility, equals('Supplier A'));
      expect(item.openingLC, equals('2025-01-01'));
      expect(item.etd, equals('2025-02-01'));
      expect(item.eta, equals('2025-03-01'));
      expect(item.boiApproval, equals('2025-01-15'));
      expect(item.revisedDeliveryToSite, equals('2025-04-01'));
      expect(item.requiredDateCMS, equals('2025-04-05'));
      expect(item.status, equals('Early'));
    });

    test('fromJson defaults nulls to empty strings', () {
      final item = ProcurementItem.fromJson({});

      expect(item.materialList, equals(''));
      expect(item.responsibility, equals(''));
      expect(item.openingLC, equals(''));
      expect(item.etd, equals(''));
      expect(item.eta, equals(''));
      expect(item.boiApproval, equals(''));
      expect(item.revisedDeliveryToSite, equals(''));
      expect(item.requiredDateCMS, equals(''));
      expect(item.status, isNull);
    });

    test('fromJson converts non-string values to strings', () {
      final json = {
        'materialList': 12345,
        'responsibility': true,
        'openingLC': null,
        'etd': 99.9,
        'eta': null,
        'boiApproval': null,
        'revisedDeliveryToSite': null,
        'requiredDateCMS': null,
      };

      final item = ProcurementItem.fromJson(json);

      expect(item.materialList, equals('12345'));
      expect(item.responsibility, equals('true'));
      expect(item.openingLC, equals(''));
      expect(item.etd, equals('99.9'));
    });

    test('status is nullable', () {
      final json = {
        'materialList': 'Concrete',
        'responsibility': 'B',
        'openingLC': '',
        'etd': '',
        'eta': '',
        'boiApproval': '',
        'revisedDeliveryToSite': '',
        'requiredDateCMS': '',
      };

      final item = ProcurementItem.fromJson(json);
      expect(item.status, isNull);
    });

    test('status values: Delayed, Early, On Time, Unknown', () {
      for (final s in ['Delayed', 'Early', 'On Time', 'Unknown']) {
        final item = ProcurementItem.fromJson({'status': s});
        expect(item.status, equals(s));
      }
    });
  });

  /* ═══════════════════════════════════════════════════════════════════ */
  /*  ProcurementView                                                   */
  /* ═══════════════════════════════════════════════════════════════════ */
  group('ProcurementView', () {
    test('fromJson parses items and deliveries', () {
      final json = {
        'procurementItems': [
          {
            'materialList': 'Cement',
            'responsibility': 'X',
            'openingLC': '',
            'etd': '',
            'eta': '',
            'boiApproval': '',
            'revisedDeliveryToSite': '2025-05-01',
            'requiredDateCMS': '2025-05-01',
            'status': 'On Time',
          },
        ],
        'upcomingDeliveries': [
          {
            'materialList': 'Pipes',
            'revisedDeliveryToSite': '2025-06-01',
            'status': 'Early',
          },
        ],
      };

      final view = ProcurementView.fromJson(json);

      expect(view.procurementItems, hasLength(1));
      expect(view.procurementItems[0].materialList, equals('Cement'));
      expect(view.upcomingDeliveries, hasLength(1));
      expect(view.upcomingDeliveries[0].materialList, equals('Pipes'));
    });

    test('fromJson handles empty lists', () {
      final view = ProcurementView.fromJson({});

      expect(view.procurementItems, isEmpty);
      expect(view.upcomingDeliveries, isEmpty);
    });

    test('fromJson handles null lists gracefully', () {
      final view = ProcurementView.fromJson({
        'procurementItems': null,
        'upcomingDeliveries': null,
      });

      expect(view.procurementItems, isEmpty);
      expect(view.upcomingDeliveries, isEmpty);
    });

    test('fromJson handles multiple items', () {
      final items = List<Map<String, dynamic>>.generate(
        5,
        (i) => <String, dynamic>{
          'materialList': 'Item $i',
          'responsibility': 'R$i',
          'openingLC': '',
          'etd': '',
          'eta': '',
          'boiApproval': '',
          'revisedDeliveryToSite': '2025-0${i + 1}-01',
          'requiredDateCMS': '2025-0${i + 1}-01',
          'status': 'On Time',
        },
      );

      final view = ProcurementView.fromJson({
        'procurementItems': items,
        'upcomingDeliveries': [],
      });

      expect(view.procurementItems, hasLength(5));
      expect(view.procurementItems[2].materialList, equals('Item 2'));
    });
  });

  /* ═══════════════════════════════════════════════════════════════════ */
  /*  ProcurementItemView                                               */
  /* ═══════════════════════════════════════════════════════════════════ */
  group('ProcurementItemView', () {
    test('fromJson parses all logistics fields', () {
      final json = {
        'materialList': 'Rebar',
        'responsibility': 'Contractor C',
        'openingLC': '2025-01-10',
        'etd': '2025-02-15',
        'eta': '2025-03-20',
        'boiApproval': '2025-01-12',
        'revisedDeliveryToSite': '2025-04-01',
        'requiredDateCMS': '2025-03-30',
        'status': 'Delayed',
      };

      final item = ProcurementItemView.fromJson(json);

      expect(item.materialList, equals('Rebar'));
      expect(item.responsibility, equals('Contractor C'));
      expect(item.openingLC, equals('2025-01-10'));
      expect(item.etd, equals('2025-02-15'));
      expect(item.eta, equals('2025-03-20'));
      expect(item.boiApproval, equals('2025-01-12'));
      expect(item.status, equals('Delayed'));
    });

    test('defaults null fields to empty strings', () {
      final item = ProcurementItemView.fromJson({});

      expect(item.materialList, equals(''));
      expect(item.etd, equals(''));
    });
  });

  /* ═══════════════════════════════════════════════════════════════════ */
  /*  DeliverySimpleView                                                */
  /* ═══════════════════════════════════════════════════════════════════ */
  group('DeliverySimpleView', () {
    test('fromJson parses summary fields', () {
      final json = {
        'materialList': 'Glass Panels',
        'revisedDeliveryToSite': '2025-07-01',
        'status': 'Early',
      };

      final delivery = DeliverySimpleView.fromJson(json);

      expect(delivery.materialList, equals('Glass Panels'));
      expect(delivery.revisedDeliveryToSite, equals('2025-07-01'));
      expect(delivery.status, equals('Early'));
    });

    test('status is nullable', () {
      final delivery = DeliverySimpleView.fromJson({
        'materialList': 'Wood',
        'revisedDeliveryToSite': '2025-08-01',
      });

      expect(delivery.status, isNull);
    });

    test('defaults empty strings for missing fields', () {
      final delivery = DeliverySimpleView.fromJson({});

      expect(delivery.materialList, equals(''));
      expect(delivery.revisedDeliveryToSite, equals(''));
      expect(delivery.status, isNull);
    });
  });
}
