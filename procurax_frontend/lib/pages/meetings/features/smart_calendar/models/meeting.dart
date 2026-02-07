class Meeting {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String location;
  final String priority;
  final bool done;

  const Meeting({
    required this.id,
    required this.title,
    required this.date,
    this.description = '',
    this.startTime = '',
    this.endTime = '',
    this.location = '',
    this.priority = 'medium',
    this.done = false,
  });

  String get timeLabel {
    if (startTime.isEmpty && endTime.isEmpty) return 'Time TBD';
    if (startTime.isEmpty) return endTime;
    if (endTime.isEmpty) return startTime;
    return '$startTime - $endTime';
  }

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'medium',
      done: json['done'] == true,
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
    };
  }
}
