import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/error_handler.dart';
import '../../services/user_service.dart';
import 'user_list_state.dart';

class UserListCubit extends Cubit<UserListState> {
  final UserService _userService;

  UserListCubit({UserService? userService})
      : _userService = userService ?? UserService(),
        super(UserListInitial());

  Future<void> fetchUsers({String? role, String? email}) async {
    emit(UserListLoading());
    try {
      final users = await _userService.getUsers(role: role, email: email);
      emit(UserListLoaded(users));
    } catch (e) {
      emit(UserListError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      await _userService.deleteUser(userId);
      // Refresh the list after deletion
      await fetchUsers();
    } catch (e) {
      emit(UserListError(ErrorHandler.getMessage(e)));
    }
  }
}
