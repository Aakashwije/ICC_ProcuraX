enum AlertType {
  projects,
  tasks,
  procurement,
  meetings,
  notes,
  communication,
  general,
}

enum AlertPriority { critical, high, medium, low }

enum ProjectStatus { active, completed, assigned, onHold, cancelled }

class AlertModel {
  final String id;
  final String title;
  final String message;
  final AlertType type;
  final AlertPriority priority;
  final bool isRead;
  final String? projectName;
  final ProjectStatus? projectStatus;
  final String? projectId;
  final String? taskId;
  final String? meetingId;
  final String? noteId;
  final String? procurementId;
  final String? actionUrl;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    this.isRead = false,
    this.projectName,
    this.projectStatus,
    this.projectId,
    this.taskId,
    this.meetingId,
    this.noteId,
    this.procurementId,
    this.actionUrl,
    this.metadata,
    required this.timestamp,
  });

  AlertModel copyWith({
    String? id,
    String? title,
    String? message,
    AlertType? type,
    AlertPriority? priority,
    bool? isRead,
    String? projectName,
    ProjectStatus? projectStatus,
    String? projectId,
    String? taskId,
    String? meetingId,
    String? noteId,
    String? procurementId,
    String? actionUrl,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
  }) {
    return AlertModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      projectName: projectName ?? this.projectName,
      projectStatus: projectStatus ?? this.projectStatus,
      projectId: projectId ?? this.projectId,
      taskId: taskId ?? this.taskId,
      meetingId: meetingId ?? this.meetingId,
      noteId: noteId ?? this.noteId,
      procurementId: procurementId ?? this.procurementId,
      actionUrl: actionUrl ?? this.actionUrl,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Extract a string ID from a field that may be a plain string or a
  /// populated Mongoose object (Map with `_id`).
  static String? _extractId(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) return value['_id']?.toString();
    return value.toString();
  }

  // fromJson factory constructor
  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      type: _parseAlertType(json['type']?.toString()),
      priority: _parseAlertPriority(json['priority']?.toString()),
      isRead: json['isRead'] == true,
      projectName: json['projectName']?.toString(),
      projectStatus: json['projectStatus'] != null
          ? _parseProjectStatus(json['projectStatus'].toString())
          : null,
      projectId: _extractId(json['projectId']),
      taskId: _extractId(json['taskId']),
      meetingId: _extractId(json['meetingId']),
      noteId: _extractId(json['noteId']),
      procurementId: _extractId(json['procurementId']),
      actionUrl: _extractId(json['actionUrl']),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      timestamp:
          DateTime.tryParse(
            (json['createdAt'] ?? json['timestamp'] ?? '').toString(),
          ) ??
          DateTime.now(),
    );
  }

  // toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'priority': priority.name,
      'isRead': isRead,
      if (projectName != null) 'projectName': projectName,
      if (projectStatus != null) 'projectStatus': projectStatus?.name,
      if (projectId != null) 'projectId': projectId,
      if (taskId != null) 'taskId': taskId,
      if (meetingId != null) 'meetingId': meetingId,
      if (noteId != null) 'noteId': noteId,
      if (procurementId != null) 'procurementId': procurementId,
      if (actionUrl != null) 'actionUrl': actionUrl,
      if (metadata != null) 'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Get a human-readable time ago string
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  // Helper methods to parse enums
  static AlertType _parseAlertType(String? value) {
    if (value == null) return AlertType.general;
    return AlertType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AlertType.general,
    );
  }

  static AlertPriority _parseAlertPriority(String? value) {
    if (value == null) return AlertPriority.medium;
    return AlertPriority.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AlertPriority.medium,
    );
  }

  static ProjectStatus? _parseProjectStatus(String? value) {
    if (value == null) return null;
    return ProjectStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ProjectStatus.active,
    );
  }
}
