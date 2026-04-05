import 'package:equatable/equatable.dart';

class DashboardSummary extends Equatable {
  final int total;
  final int todo;
  final int inProgress;
  final int done;
  final int overdue;

  const DashboardSummary({
    required this.total,
    required this.todo,
    required this.inProgress,
    required this.done,
    required this.overdue,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      total: json['total'] as int,
      todo: json['todo'] as int,
      inProgress: json['in_progress'] as int,
      done: json['done'] as int,
      overdue: json['overdue'] as int,
    );
  }

  @override
  List<Object?> get props => [total, todo, inProgress, done, overdue];
}

class CompletionRate extends Equatable {
  final int totalTasks;
  final int completedTasks;
  final double completionPercentage;

  const CompletionRate({
    required this.totalTasks,
    required this.completedTasks,
    required this.completionPercentage,
  });

  factory CompletionRate.fromJson(Map<String, dynamic> json) {
    return CompletionRate(
      totalTasks: json['total_tasks'] as int,
      completedTasks: json['completed_tasks'] as int,
      completionPercentage: (json['completion_percentage'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [totalTasks, completedTasks, completionPercentage];
}

class PriorityBreakdown extends Equatable {
  final int low;
  final int medium;
  final int high;

  const PriorityBreakdown({
    required this.low,
    required this.medium,
    required this.high,
  });

  factory PriorityBreakdown.fromJson(Map<String, dynamic> json) {
    return PriorityBreakdown(
      low: json['low'] as int,
      medium: json['medium'] as int,
      high: json['high'] as int,
    );
  }

  @override
  List<Object?> get props => [low, medium, high];
}

class UserTaskCount extends Equatable {
  final int userId;
  final String email;
  final String fullName;
  final int taskCount;

  const UserTaskCount({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.taskCount,
  });

  factory UserTaskCount.fromJson(Map<String, dynamic> json) {
    return UserTaskCount(
      userId: json['user_id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      taskCount: json['task_count'] as int,
    );
  }

  @override
  List<Object?> get props => [userId, email, fullName, taskCount];
}

class DateRangeStats extends Equatable {
  final String? startDate;
  final String? endDate;
  final int total;
  final int completed;

  const DateRangeStats({
    this.startDate,
    this.endDate,
    required this.total,
    required this.completed,
  });

  factory DateRangeStats.fromJson(Map<String, dynamic> json) {
    return DateRangeStats(
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      total: json['total'] as int,
      completed: json['completed'] as int,
    );
  }

  @override
  List<Object?> get props => [startDate, endDate, total, completed];
}
