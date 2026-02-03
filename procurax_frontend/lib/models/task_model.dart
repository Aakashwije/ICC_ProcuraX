enum TaskPriority { low, medium, high, critical }

enum TaskStatus { todo, inProgress, blocked, done }

TaskPriority _priorityFromJson(String? value) {
  switch (value) {
    case "low":
      return TaskPriority.low;
    case "high":
      return TaskPriority.high;
    case "critical":
      return TaskPriority.critical;
    default:
      return TaskPriority.medium;
  }
}

String _priorityToJson(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.low:
      return "low";
    case TaskPriority.high:
      return "high";
    case TaskPriority.critical:
      return "critical";
    case TaskPriority.medium:
      return "medium";
  }
}

TaskStatus _statusFromJson(String? value) {
  switch (value) {
    case "in_progress":
      return TaskStatus.inProgress;
    case "blocked":
      return TaskStatus.blocked;
    case "done":
      return TaskStatus.done;
    default:
      return TaskStatus.todo;
  }
}

String _statusToJson(TaskStatus status) {
  switch (status) {
    case TaskStatus.inProgress:
      return "in_progress";
    case TaskStatus.blocked:
      return "blocked";
    case TaskStatus.done:
      return "done";
    case TaskStatus.todo:
      return "todo";
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final String assignee;
  final List<String> tags;
  final bool isArchived;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.assignee,
    required this.tags,
    required this.isArchived,
  });

  bool get completed => status == TaskStatus.done;

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    String? assignee,
    List<String>? tags,
    bool? isArchived,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      assignee: assignee ?? this.assignee,
      tags: tags ?? this.tags,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final dueDateValue = json["dueDate"];
    DateTime? parsedDueDate;
    if (dueDateValue is String && dueDateValue.isNotEmpty) {
      parsedDueDate = DateTime.tryParse(dueDateValue);
    }

    return Task(
      id: json["id"]?.toString() ?? json["_id"]?.toString() ?? "",
      title: json["title"]?.toString() ?? "",
      description: json["description"]?.toString() ?? "",
      status: _statusFromJson(json["status"]?.toString()),
      priority: _priorityFromJson(json["priority"]?.toString()),
      dueDate: parsedDueDate,
      assignee: json["assignee"]?.toString() ?? "",
      tags: (json["tags"] is List)
          ? (json["tags"] as List).map((e) => e.toString()).toList()
          : <String>[],
      isArchived: json["isArchived"] == true,
    );
  }

  Map<String, dynamic> toCreateJson() => {
        "title": title,
        "description": description,
        "status": _statusToJson(status),
        "priority": _priorityToJson(priority),
        "dueDate": dueDate?.toIso8601String(),
        "assignee": assignee,
        "tags": tags,
      };

  Map<String, dynamic> toUpdateJson() => {
        "title": title,
        "description": description,
        "status": _statusToJson(status),
        "priority": _priorityToJson(priority),
        "dueDate": dueDate?.toIso8601String(),
        "assignee": assignee,
        "tags": tags,
        "isArchived": isArchived,
      };
}
