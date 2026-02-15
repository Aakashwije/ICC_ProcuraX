/*
  Note model used by the UI.
*/
class Note {
  final String id;
  final String title;
  final String content;
  final String tag;
  final DateTime createdAt;
  final DateTime lastEdited;
  final bool hasAttachment;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.tag,
    required this.createdAt,
    required this.lastEdited,
    required this.hasAttachment,
  });

  /*
    Copy helper to create a new Note with updated fields.
  */
  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? tag,
    DateTime? createdAt,
    DateTime? lastEdited,
    bool? hasAttachment,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      tag: tag ?? this.tag,
      createdAt: createdAt ?? this.createdAt,
      lastEdited: lastEdited ?? this.lastEdited,
      hasAttachment: hasAttachment ?? this.hasAttachment,
    );
  }

  /*
    Build a Note from backend JSON.
  */
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
    );
  }

  /*
    Convert Note into JSON for create/update requests.
  */
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
