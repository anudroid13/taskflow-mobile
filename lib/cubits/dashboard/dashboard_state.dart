import 'package:equatable/equatable.dart';
import '../../models/dashboard.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardSummary summary;
  final CompletionRate completionRate;
  final PriorityBreakdown priorityBreakdown;
  final List<UserTaskCount>? userCounts; // null for employees
  final DateRangeStats? dateRangeStats;

  const DashboardLoaded({
    required this.summary,
    required this.completionRate,
    required this.priorityBreakdown,
    this.userCounts,
    this.dateRangeStats,
  });

  @override
  List<Object?> get props => [
        summary,
        completionRate,
        priorityBreakdown,
        userCounts,
        dateRangeStats,
      ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
