import 'package:flutter_test/flutter_test.dart';
import 'package:procurax_frontend/pages/meetings/features/smart_calendar/models/meeting.dart';

void main() {
  /* ═══════════════════════════════════════════════════════════════════ */
  /*  Meeting Model                                                     */
  /* ═══════════════════════════════════════════════════════════════════ */
  group('Meeting.fromJson', () {
    test('parses complete JSON correctly', () {
      final json = {
        '_id': 'meeting_1',
        'title': 'Daily Standup',
        'description': 'Team sync',
        'startTime': '2025-06-15T09:00:00.000Z',
        'endTime': '2025-06-15T09:30:00.000Z',
        'location': 'Conference Room A',
        'done': false,
      };

      final meeting = Meeting.fromJson(json);

      expect(meeting.id, equals('meeting_1'));
      expect(meeting.title, equals('Daily Standup'));
      expect(meeting.description, equals('Team sync'));
      expect(meeting.location, equals('Conference Room A'));
      expect(meeting.isDone, isFalse);
    });

    test('uses id field when _id is missing', () {
      final json = {
        'id': 'fallback_id',
        'title': 'Review',
        'description': '',
        'startTime': '2025-06-15T10:00:00.000Z',
        'endTime': '2025-06-15T11:00:00.000Z',
        'location': '',
      };

      final meeting = Meeting.fromJson(json);
      expect(meeting.id, equals('fallback_id'));
    });

    test('defaults title to empty string when null', () {
      final meeting = Meeting.fromJson({});
      expect(meeting.title, equals(''));
    });

    test('defaults description to empty string when null', () {
      final meeting = Meeting.fromJson({});
      expect(meeting.description, equals(''));
    });

    test('defaults isDone to false when not present', () {
      final meeting = Meeting.fromJson({
        'title': 'Test',
        'startTime': '2025-06-15T09:00:00.000Z',
        'endTime': '2025-06-15T10:00:00.000Z',
      });
      expect(meeting.isDone, isFalse);
    });

    test('parses isDone=true from done field', () {
      final meeting = Meeting.fromJson({
        'done': true,
        'startTime': '2025-06-15T09:00:00.000Z',
        'endTime': '2025-06-15T10:00:00.000Z',
      });
      expect(meeting.isDone, isTrue);
    });

    test('parses UTC dates and converts to local', () {
      final meeting = Meeting.fromJson({
        'startTime': '2025-06-15T09:00:00.000Z',
        'endTime': '2025-06-15T10:00:00.000Z',
      });

      // Dates from UTC should be converted to local
      expect(meeting.startTime, isA<DateTime>());
      expect(meeting.endTime, isA<DateTime>());
    });

    test('fallback to DateTime.now() for invalid date', () {
      final before = DateTime.now();
      final meeting = Meeting.fromJson({
        'startTime': 'invalid-date',
        'endTime': 'also-invalid',
      });
      final after = DateTime.now();

      // Should fall back to around now
      expect(
        meeting.startTime.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        meeting.endTime.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('id is nullable', () {
      final meeting = Meeting.fromJson({
        'startTime': '2025-06-15T09:00:00.000Z',
        'endTime': '2025-06-15T10:00:00.000Z',
      });
      expect(meeting.id, isNull);
    });
  });

  /* ═══════════════════════════════════════════════════════════════════ */
  /*  Meeting.toJson                                                    */
  /* ═══════════════════════════════════════════════════════════════════ */
  group('Meeting.toJson', () {
    test('serializes all fields correctly', () {
      final meeting = Meeting(
        title: 'Sprint Planning',
        description: 'Plan next sprint',
        startTime: DateTime.utc(2025, 6, 15, 9, 0),
        endTime: DateTime.utc(2025, 6, 15, 10, 0),
        location: 'Room B',
        isDone: false,
      );

      final json = meeting.toJson();

      expect(json['title'], equals('Sprint Planning'));
      expect(json['description'], equals('Plan next sprint'));
      expect(json['location'], equals('Room B'));
      expect(json['done'], isFalse);
    });

    test('serializes dates as ISO 8601 UTC', () {
      final meeting = Meeting(
        title: 'Test',
        description: '',
        startTime: DateTime.utc(2025, 6, 15, 14, 30),
        endTime: DateTime.utc(2025, 6, 15, 15, 30),
        location: '',
      );

      final json = meeting.toJson();

      expect(json['startTime'], equals('2025-06-15T14:30:00.000Z'));
      expect(json['endTime'], equals('2025-06-15T15:30:00.000Z'));
    });

    test('does not include id in toJson', () {
      final meeting = Meeting(
        id: 'meeting_99',
        title: 'Test',
        description: '',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        location: '',
      );

      final json = meeting.toJson();
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('_id'), isFalse);
    });
  });

  /* ═══════════════════════════════════════════════════════════════════ */
  /*  Meeting.copyWith                                                  */
  /* ═══════════════════════════════════════════════════════════════════ */
  group('Meeting.copyWith', () {
    final original = Meeting(
      id: 'm1',
      title: 'Original',
      description: 'Desc',
      startTime: DateTime.utc(2025, 1, 1, 9, 0),
      endTime: DateTime.utc(2025, 1, 1, 10, 0),
      location: 'Room A',
      isDone: false,
    );

    test('copies with new title', () {
      final updated = original.copyWith(title: 'Updated');
      expect(updated.title, equals('Updated'));
      expect(updated.description, equals('Desc'));
      expect(updated.id, equals('m1'));
    });

    test('copies with new isDone', () {
      final updated = original.copyWith(isDone: true);
      expect(updated.isDone, isTrue);
      expect(updated.title, equals('Original'));
    });

    test('copies with new location', () {
      final updated = original.copyWith(location: 'Room B');
      expect(updated.location, equals('Room B'));
    });

    test('copies with new times', () {
      final newStart = DateTime.utc(2025, 2, 1, 14, 0);
      final updated = original.copyWith(startTime: newStart);
      expect(updated.startTime, equals(newStart));
      expect(updated.endTime, equals(original.endTime));
    });

    test('preserves all fields when no args given', () {
      final copy = original.copyWith();
      expect(copy.id, equals(original.id));
      expect(copy.title, equals(original.title));
      expect(copy.description, equals(original.description));
      expect(copy.location, equals(original.location));
      expect(copy.isDone, equals(original.isDone));
    });
  });

  /* ═══════════════════════════════════════════════════════════════════ */
  /*  Meeting.timeRange                                                 */
  /* ═══════════════════════════════════════════════════════════════════ */
  group('Meeting.timeRange', () {
    test('formats time range correctly', () {
      final meeting = Meeting(
        title: 'Test',
        description: '',
        startTime: DateTime(2025, 6, 15, 9, 0),
        endTime: DateTime(2025, 6, 15, 10, 30),
        location: '',
      );

      expect(meeting.timeRange, equals('09:00 - 10:30'));
    });

    test('pads single digit hours and minutes', () {
      final meeting = Meeting(
        title: 'Test',
        description: '',
        startTime: DateTime(2025, 6, 15, 8, 5),
        endTime: DateTime(2025, 6, 15, 9, 0),
        location: '',
      );

      expect(meeting.timeRange, equals('08:05 - 09:00'));
    });

    test('handles midnight times', () {
      final meeting = Meeting(
        title: 'Test',
        description: '',
        startTime: DateTime(2025, 6, 15, 0, 0),
        endTime: DateTime(2025, 6, 15, 0, 30),
        location: '',
      );

      expect(meeting.timeRange, equals('00:00 - 00:30'));
    });

    test('handles late night times', () {
      final meeting = Meeting(
        title: 'Test',
        description: '',
        startTime: DateTime(2025, 6, 15, 23, 45),
        endTime: DateTime(2025, 6, 16, 0, 15),
        location: '',
      );

      expect(meeting.timeRange, equals('23:45 - 00:15'));
    });
  });
}
