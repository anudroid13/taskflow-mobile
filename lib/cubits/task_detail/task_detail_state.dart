import 'package:equatable/equatable.dart';
import '../../models/attachment.dart';
import '../../models/task.dart';
import '../../models/user.dart';

abstract class TaskDetailState extends Equatable {
  const TaskDetailState();

  @override
  List<Object?> get props => [];
}

class TaskDetailInitial extends TaskDetailState {}

class TaskDetailLoading extends TaskDetailState {}

class TaskDetailLoaded extends TaskDetailState {
  final Task task;
  final List<Attachment> attachments;
  final User? owner;

  const TaskDetailLoaded({required this.task, required this.attachments, this.owner});

  @override
  List<Object?> get props => [task, attachments, owner];
}

class TaskDetailError extends TaskDetailState {
  final String message;

  const TaskDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

class TaskDetailUploading extends TaskDetailState {
  final Task task;
  final List<Attachment> attachments;
  final double progress;

  const TaskDetailUploading({
    required this.task,
    required this.attachments,
    required this.progress,
  });

  @override
  List<Object?> get props => [task, attachments, progress];
}
