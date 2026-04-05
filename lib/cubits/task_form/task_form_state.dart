import 'package:equatable/equatable.dart';

abstract class TaskFormState extends Equatable {
  const TaskFormState();

  @override
  List<Object?> get props => [];
}

class TaskFormInitial extends TaskFormState {}

class TaskFormLoading extends TaskFormState {}

class TaskFormSuccess extends TaskFormState {}

class TaskFormError extends TaskFormState {
  final String message;

  const TaskFormError(this.message);

  @override
  List<Object?> get props => [message];
}
