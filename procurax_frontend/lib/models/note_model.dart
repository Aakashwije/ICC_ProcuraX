/// Represents a single note created by a user.
///
/// Notes are stored in MongoDB via the backend and fetched as JSON.
/// The [hasAttachment] flag is true when a file has been uploaded to
/// Cloudinary for this note. [attachmentUrl] and [attachmentName] carry
/// the download URL and original filename of that file.
class Note {
  /// MongoDB document ID (mapped from `_id` or `id` in the API response).
  final String id;

  /// Short headline for the note.
  final String title;

  /// Full body text of the note.
  final String content;

  /// Category label — one of "Issue", "Meeting", or "Reminder".
  final String tag;

  /// When the note was first created.
  final DateTime createdAt;

  /// When the note was most recently edited.
  final DateTime lastEdited;

  /// True when a file attachment has been uploaded to this note.
  final bool hasAttachment;

  /// Public Cloudinary URL for the attached file.
  /// Empty string when no attachment exists.
  final String attachmentUrl;

  /// Original filename of the attached file (e.g. "site_photo.jpg").
  /// Empty string when no attachment exists.
  final String attachmentName;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.tag,
    required this.createdAt,
    required this.lastEdited,
    required this.hasAttachment,
    this.attachmentUrl = "",
    this.attachmentName = "",
  });

  /// Returns a copy of this note with any provided fields overridden.
  ///
  /// Used when updating a note locally before sending it to the API.
  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? tag,
    DateTime? createdAt,
    DateTime? lastEdited,
    bool? hasAttachment,
    String? attachmentUrl,
    String? attachmentName,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      tag: tag ?? this.tag,
      createdAt: createdAt ?? this.createdAt,
      lastEdited: lastEdited ?? this.lastEdited,
      hasAttachment: hasAttachment ?? this.hasAttachment,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
    );
  }

  /// Deserialises a note from a JSON map returned by the backend API.
  ///
  /// Handles both `id` and `_id` keys because MongoDB returns `_id`
  /// while the service layer normalises it to `id`.
  /// All string fields fall back to sensible defaults if null/missing.
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json["id"]?.toString() ?? json["_id"]?.toString() ?? "",
      title: json["title"]?.toString() ?? "",
      content: json["content"]?.toString() ?? "",
      tag: json["tag"]?.toString() ?? "Issue",
      createdAt:
          DateTime.tryParse(json["createdAt"]?.toString() ?? "") ??
          DateTime.now(),
      lastEdited:
          DateTime.tryParse(json["lastEdited"]?.toString() ?? "") ??
          DateTime.now(),
      hasAttachment: json["hasAttachment"] == true,
      attachmentUrl: json["attachmentUrl"]?.toString() ?? "",
      attachmentName: json["attachmentName"]?.toString() ?? "",
    );
  }

  /// Serialises this note to a JSON map for sending to the backend API.
  ///
  /// Attachment fields are intentionally excluded because attachments are
  /// uploaded via a separate multipart endpoint, not the create/update body.
  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "content": content,
      "tag": tag,
      "createdAt": createdAt.toIso8601String(),
      "lastEdited": lastEdited.toIso8601String(),
      "hasAttachment": hasAttachment,
    };
  }
}
