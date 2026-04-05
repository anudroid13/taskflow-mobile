import 'package:equatable/equatable.dart';
import '../../models/task.dart';

abstract class TaskListState extends Equatable {
  const TaskListState();

  @override
  List<Object?> get props => [];
}

class TaskListInitial extends TaskListState {}

class TaskListLoading extends TaskListState {}

class TaskListLoaded extends TaskListState {
  final List<Task> tasks;

  const TaskListLoaded(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

class TaskListError extends TaskListState {
  final String message;

  const TaskListError(this.message);

  @override
  List<Object?> get props => [message];
}
