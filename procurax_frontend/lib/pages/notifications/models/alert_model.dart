import 'package:flutter/material.dart';

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
}
