/// ============================================================================
/// Task Model Unit Tests
/// ============================================================================
///
/// Tests the [Task] model class:
///   - JSON deserialisation (fromJson)
///   - JSON serialisation (toCreateJson / toUpdateJson)
///   - copyWith immutability
///   - Enum conversions (priority / status)
///   - Edge cases and null safety
///
/// Run: flutter test test/unit/task_model_test.dart
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:procurax_frontend/models/task_model.dart';

void main() {
  group('Task Model — JSON Deserialisation', () {
    test('parses a complete JSON map', () {
      final json = {
        '_id': '507f1f77bcf86cd799439011',
        'title': 'Review PR',
        'description': 'Check the latest pull request',
        'status': 'in_progress',
        'priority': 'high',
        'dueDate': '2026-04-01T00:00:00.000Z',
        'assignee': 'Aakash',
        'tags': ['urgent', 'review'],
        'isArchived': false,
      };

      final task = Task.fromJson(json);

      expect(task.id, '507f1f77bcf86cd799439011');
      expect(task.title, 'Review PR');
      expect(task.description, 'Check the latest pull request');
      expect(task.status, TaskStatus.inProgress);
      expect(task.priority, TaskPriority.high);
      expect(task.dueDate, isNotNull);
      expect(task.dueDate!.year, 2026);
      expect(task.assignee, 'Aakash');
      expect(task.tags, ['urgent', 'review']);
      expect(task.isArchived, false);
    });

    test('falls back to "id" when "_id" is missing', () {
      final json = {
        'id': 'abc123',
        'title': 'Test',
        'description': '',
        'status': 'todo',
        'priority': 'low',
        'tags': <String>[],
      };

      final task = Task.fromJson(json);
      expect(task.id, 'abc123');
    });

    test('handles null / missing fields with safe defaults', () {
      final task = Task.fromJson(<String, dynamic>{});

      expect(task.id, '');
      expect(task.title, '');
      expect(task.description, '');
      expect(task.status, TaskStatus.todo); // default
      expect(task.priority, TaskPriority.medium); // default
      expect(task.dueDate, isNull);
      expect(task.assignee, '');
      expect(task.tags, isEmpty);
      expect(task.isArchived, false);
    });

    test('ignores invalid dueDate strings', () {
      final task = Task.fromJson({'dueDate': 'not-a-date'});
      expect(task.dueDate, isNull);
    });

    test('handles tags when not a list', () {
      final task = Task.fromJson({'tags': 'single-string'});
      expect(task.tags, isEmpty);
    });
  });

  group('Task Model — JSON Serialisation', () {
    final task = Task(
      id: '123',
      title: 'Build feature',
      description: 'Implement caching',
      status: TaskStatus.inProgress,
      priority: TaskPriority.high,
      dueDate: DateTime(2026, 6, 15),
      assignee: 'Dev',
      tags: ['backend', 'redis'],
      isArchived: false,
    );

    test('toCreateJson includes all creation fields', () {
      final json = task.toCreateJson();

      expect(json['title'], 'Build feature');
      expect(json['description'], 'Implement caching');
      expect(json['status'], 'in_progress');
      expect(json['priority'], 'high');
      expect(json['dueDate'], isNotNull);
      expect(json['assignee'], 'Dev');
      expect(json['tags'], ['backend', 'redis']);
      // Should NOT include id or isArchived for creation
      expect(json.containsKey('id'), false);
    });

    test('toUpdateJson includes isArchived field', () {
      final json = task.toUpdateJson();

      expect(json['isArchived'], false);
      expect(json['title'], 'Build feature');
    });
  });

  group('Task Model — copyWith', () {
    test('returns a new instance with overridden fields', () {
      final original = Task(
        id: '1',
        title: 'Original',
        description: 'Desc',
        status: TaskStatus.todo,
        priority: TaskPriority.low,
        dueDate: null,
        assignee: '',
        tags: const [],
        isArchived: false,
      );

      final updated = original.copyWith(
        title: 'Updated',
        status: TaskStatus.done,
        isArchived: true,
      );

      // Updated fields
      expect(updated.title, 'Updated');
      expect(updated.status, TaskStatus.done);
      expect(updated.isArchived, true);

      // Unchanged fields
      expect(updated.id, '1');
      expect(updated.description, 'Desc');
      expect(updated.priority, TaskPriority.low);

      // Original is untouched
      expect(original.title, 'Original');
      expect(original.status, TaskStatus.todo);
    });
  });

  group('Task Model — Enum Conversions', () {
    test('all priority values round-trip correctly', () {
      for (final p in TaskPriority.values) {
        final json = Task(
          id: '',
          title: '',
          description: '',
          status: TaskStatus.todo,
          priority: p,
          dueDate: null,
          assignee: '',
          tags: const [],
          isArchived: false,
        ).toCreateJson();

        final restored = Task.fromJson(json);
        expect(restored.priority, p);
      }
    });

    test('all status values round-trip correctly', () {
      for (final s in TaskStatus.values) {
        final json = Task(
          id: '',
          title: '',
          description: '',
          status: s,
          priority: TaskPriority.low,
          dueDate: null,
          assignee: '',
          tags: const [],
          isArchived: false,
        ).toCreateJson();

        final restored = Task.fromJson(json);
        expect(restored.status, s);
      }
    });
  });

  group('Task Model — computed properties', () {
    test('completed returns true when status is done', () {
      final task = Task(
        id: '',
        title: '',
        description: '',
        status: TaskStatus.done,
        priority: TaskPriority.low,
        dueDate: null,
        assignee: '',
        tags: const [],
        isArchived: false,
      );

      expect(task.completed, true);
    });

    test('completed returns false for non-done statuses', () {
      for (final s in [
        TaskStatus.todo,
        TaskStatus.inProgress,
        TaskStatus.blocked,
      ]) {
        final task = Task(
          id: '',
          title: '',
          description: '',
          status: s,
          priority: TaskPriority.low,
          dueDate: null,
          assignee: '',
          tags: const [],
          isArchived: false,
        );

        expect(
          task.completed,
          false,
          reason: 'Status $s should not be completed',
        );
      }
    });
  });
}
