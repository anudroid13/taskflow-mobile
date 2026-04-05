import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/error_handler.dart';
import '../../services/user_service.dart';
import 'user_form_state.dart';

class UserFormCubit extends Cubit<UserFormState> {
  final UserService _userService;

  UserFormCubit({UserService? userService})
      : _userService = userService ?? UserService(),
        super(UserFormInitial());

  Future<void> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    bool isActive = true,
  }) async {
    emit(UserFormLoading());
    try {
      await _userService.createUser(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        isActive: isActive,
      );
      emit(UserFormSuccess());
    } catch (e) {
      emit(UserFormError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> updateUser(int userId, Map<String, dynamic> data) async {
    emit(UserFormLoading());
    try {
      await _userService.updateUser(userId, data);
      emit(UserFormSuccess());
    } catch (e) {
      emit(UserFormError(ErrorHandler.getMessage(e)));
    }
  }
}
