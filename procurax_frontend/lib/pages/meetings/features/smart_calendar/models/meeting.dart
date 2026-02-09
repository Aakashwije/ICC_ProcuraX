class Meeting {
  final String id;
  final String title;
  final String time;
  final DateTime date;
  final String description;
  final String location;
  final String priority;
  final bool done;
  final String startTime;
  final String endTime;

  Meeting(
    this.title,
    this.time,
    this.date, {
    this.id = '',
    this.description = '',
    this.location = '',
    this.priority = 'medium',
    this.done = false,
    this.startTime = '',
    this.endTime = '',
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    final start = json['startTime']?.toString() ?? '';
    final end = json['endTime']?.toString() ?? '';
    final timeLabel = json['time']?.toString() ?? _formatTime(start, end);

    return Meeting(
      json['title']?.toString() ?? '',
      timeLabel,
      DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'medium',
      done: json['done'] == true,
      startTime: start,
      endTime: end,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'priority': priority,
      'done': done,
      'time': time,
    };
  }

  String get timeLabel => time;

  static String _formatTime(String start, String end) {
    if (start.isEmpty && end.isEmpty) return '';
    if (start.isEmpty) return end;
    if (end.isEmpty) return start;
    return '$start - $end';
  }
}
