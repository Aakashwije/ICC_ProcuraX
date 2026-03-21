/// ============================================================================
/// Note Model Unit Tests
/// ============================================================================
///
/// Tests the [Note] model class:
///   - JSON deserialisation (fromJson) with various field combinations
///   - JSON serialisation (toJson)
///   - copyWith immutability
///   - Attachment handling (hasAttachment, URL, name)
///   - Date parsing edge cases
///
/// Run: flutter test test/unit/note_model_test.dart
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:procurax_frontend/models/note_model.dart';

void main() {
  group('Note Model — JSON Deserialisation', () {
    test('parses a complete JSON map', () {
      final json = {
        '_id': '507f1f77bcf86cd799439022',
        'title': 'Site Visit Notes',
        'content': 'Inspected foundation work on Block A.',
        'tag': 'Meeting',
        'createdAt': '2026-03-01T10:00:00.000Z',
        'lastEdited': '2026-03-10T14:30:00.000Z',
        'hasAttachment': true,
        'attachmentUrl': 'https://cloudinary.com/photo.jpg',
        'attachmentName': 'site_photo.jpg',
      };

      final note = Note.fromJson(json);

      expect(note.id, '507f1f77bcf86cd799439022');
      expect(note.title, 'Site Visit Notes');
      expect(note.content, 'Inspected foundation work on Block A.');
      expect(note.tag, 'Meeting');
      expect(note.createdAt.year, 2026);
      expect(note.lastEdited.month, 3);
      expect(note.hasAttachment, true);
      expect(note.attachmentUrl, 'https://cloudinary.com/photo.jpg');
      expect(note.attachmentName, 'site_photo.jpg');
    });

    test('uses "id" key when "_id" is missing', () {
      final note = Note.fromJson({'id': 'abc123'});
      expect(note.id, 'abc123');
    });

    test('falls back to safe defaults for missing fields', () {
      final note = Note.fromJson(<String, dynamic>{});

      expect(note.id, '');
      expect(note.title, '');
      expect(note.content, '');
      expect(note.tag, 'Issue'); // default tag
      expect(note.hasAttachment, false);
      expect(note.attachmentUrl, '');
      expect(note.attachmentName, '');
    });

    test('handles null date strings gracefully', () {
      final note = Note.fromJson({
        'createdAt': null,
        'lastEdited': 'invalid-date',
      });

      // Should fall back to DateTime.now() (approximately)
      expect(note.createdAt.year, DateTime.now().year);
      expect(note.lastEdited.year, DateTime.now().year);
    });

    test('handles hasAttachment when not boolean', () {
      final noteTrue = Note.fromJson({'hasAttachment': true});
      final noteFalse = Note.fromJson({
        'hasAttachment': 'yes',
      }); // truthy but not true

      expect(noteTrue.hasAttachment, true);
      expect(noteFalse.hasAttachment, false); // Only exact `true` matches
    });
  });

  group('Note Model — JSON Serialisation', () {
    test('toJson includes all editable fields', () {
      final note = Note(
        id: '123',
        title: 'Test Note',
        content: 'Some content',
        tag: 'Reminder',
        createdAt: DateTime(2026, 1, 1),
        lastEdited: DateTime(2026, 1, 2),
        hasAttachment: false,
      );

      final json = note.toJson();

      expect(json['title'], 'Test Note');
      expect(json['content'], 'Some content');
      expect(json['tag'], 'Reminder');
      expect(json['createdAt'], isNotNull);
      expect(json['lastEdited'], isNotNull);
      expect(json['hasAttachment'], false);

      // Should NOT include attachment URL/name (separate upload endpoint)
      expect(json.containsKey('attachmentUrl'), false);
      expect(json.containsKey('attachmentName'), false);
    });
  });

  group('Note Model — copyWith', () {
    test('creates a new instance with overridden fields', () {
      final original = Note(
        id: '1',
        title: 'Original Title',
        content: 'Original content',
        tag: 'Issue',
        createdAt: DateTime(2026, 1, 1),
        lastEdited: DateTime(2026, 1, 1),
        hasAttachment: false,
      );

      final updated = original.copyWith(
        title: 'Updated Title',
        tag: 'Meeting',
        hasAttachment: true,
        attachmentUrl: 'https://example.com/file.pdf',
        attachmentName: 'file.pdf',
      );

      // Updated fields
      expect(updated.title, 'Updated Title');
      expect(updated.tag, 'Meeting');
      expect(updated.hasAttachment, true);
      expect(updated.attachmentUrl, 'https://example.com/file.pdf');
      expect(updated.attachmentName, 'file.pdf');

      // Unchanged fields
      expect(updated.id, '1');
      expect(updated.content, 'Original content');

      // Original is untouched
      expect(original.title, 'Original Title');
      expect(original.hasAttachment, false);
    });
  });

  group('Note Model — Attachment handling', () {
    test('note without attachment has empty URL and name', () {
      final note = Note(
        id: '1',
        title: 'No Attachment',
        content: 'Plain note',
        tag: 'Issue',
        createdAt: DateTime.now(),
        lastEdited: DateTime.now(),
        hasAttachment: false,
      );

      expect(note.attachmentUrl, '');
      expect(note.attachmentName, '');
    });

    test('note with attachment has URL and name', () {
      final note = Note(
        id: '2',
        title: 'With Attachment',
        content: 'Has a file',
        tag: 'Issue',
        createdAt: DateTime.now(),
        lastEdited: DateTime.now(),
        hasAttachment: true,
        attachmentUrl: 'https://res.cloudinary.com/test/image.png',
        attachmentName: 'image.png',
      );

      expect(note.attachmentUrl, contains('cloudinary'));
      expect(note.attachmentName, 'image.png');
    });
  });
}
