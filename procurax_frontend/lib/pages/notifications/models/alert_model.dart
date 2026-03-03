enum AlertType { projects, tasks, procurement, meetings, general }

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
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // fromJson factory constructor
  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      message: json['message'],
      type: _parseAlertType(json['type']),
      priority: _parseAlertPriority(json['priority']),
      isRead: json['isRead'] ?? false,
      projectName: json['projectName'],
      projectStatus: json['projectStatus'] != null
          ? _parseProjectStatus(json['projectStatus'])
          : null,
      projectId: json['projectId'],
      timestamp: DateTime.parse(
        json['createdAt'] ??
            json['timestamp'] ??
            DateTime.now().toIso8601String(),
      ),
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
      'projectName': projectName,
      'projectStatus': projectStatus?.name,
      'projectId': projectId,
      'timestamp': timestamp.toIso8601String(),
    };
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
