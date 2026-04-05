import 'package:equatable/equatable.dart';

enum TaskStatus { todo, in_progress, done, overdue }
enum TaskPriority { low, medium, high }

TaskStatus taskStatusFromString(String value) {
  return TaskStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => TaskStatus.todo,
  );
}

TaskPriority taskPriorityFromString(String value) {
  return TaskPriority.values.firstWhere(
    (e) => e.name == value,
    orElse: () => TaskPriority.medium,
  );
}

class Task extends Equatable {
  final int id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final int ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: taskStatusFromString(json['status'] as String),
      priority: taskPriorityFromString(json['priority'] as String),
      ownerId: json['owner_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'status': status.name,
      'priority': priority.name,
      'owner_id': ownerId,
    };
  }

  /// Returns the set of statuses this task can transition to.
  List<TaskStatus> get validTransitions {
    switch (status) {
      case TaskStatus.todo:
        return [TaskStatus.in_progress];
      case TaskStatus.in_progress:
        return [TaskStatus.done, TaskStatus.todo];
      case TaskStatus.overdue:
        return [TaskStatus.in_progress];
      case TaskStatus.done:
        return [];
    }
  }

  @override
  List<Object?> get props =>
      [id, title, description, status, priority, ownerId, createdAt, updatedAt];
}
