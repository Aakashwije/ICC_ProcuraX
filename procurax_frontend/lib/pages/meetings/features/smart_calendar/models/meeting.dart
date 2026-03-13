class Meeting {
  final String? id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final bool isDone;

  Meeting({
    this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.location,
    this.isDone = false,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      final parsed = DateTime.tryParse(value?.toString() ?? '');
      if (parsed == null) return null;
      return parsed.isUtc ? parsed.toLocal() : parsed;
    }

    return Meeting(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      startTime: parseDate(json['startTime']) ?? DateTime.now(),
      endTime: parseDate(json['endTime']) ?? DateTime.now(),
      location: json['location'] ?? '',
      isDone: json['done'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'startTime': startTime.toUtc().toIso8601String(),
      'endTime': endTime.toUtc().toIso8601String(),
      'location': location,
      'done': isDone,
    };
  }

  /// Create a copy with updated fields
  Meeting copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    bool? isDone,
  }) {
    return Meeting(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      isDone: isDone ?? this.isDone,
    );
  }

  String get timeRange {
    final start =
        "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}";
    final end =
        "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";
    return "$start - $end";
  }
}
