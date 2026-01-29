class Note {
  final String id;
  final String title;
  final String content;
  final String tag;
  final String location;
  final DateTime createdAt;
  final DateTime lastEdited;
  final bool hasAttachment;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.tag,
    required this.location,
    required this.createdAt,
    required this.lastEdited,
    required this.hasAttachment,
  });
}
