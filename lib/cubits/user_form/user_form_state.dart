import 'package:equatable/equatable.dart';

abstract class UserFormState extends Equatable {
  const UserFormState();

  @override
  List<Object?> get props => [];
}

class UserFormInitial extends UserFormState {}

class UserFormLoading extends UserFormState {}

class UserFormSuccess extends UserFormState {}

class UserFormError extends UserFormState {
  final String message;

  const UserFormError(this.message);

  @override
  List<Object?> get props => [message];
}
