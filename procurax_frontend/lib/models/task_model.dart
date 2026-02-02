enum TaskPriority { low, medium, high }

class Task {
  final String id;
  final String title;
  final String description;
  final String location;
  final String city;
  final DateTime deadline;
  final TaskPriority priority;
  final String assignedTo;
  final bool completed;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.city,
    required this.deadline,
    required this.priority,
    required this.assignedTo,
    this.completed = false,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    String? city,
    DateTime? deadline,
    TaskPriority? priority,
    String? assignedTo,
    bool? completed,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      city: city ?? this.city,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      assignedTo: assignedTo ?? this.assignedTo,
      completed: completed ?? this.completed,
    );
  }
}
