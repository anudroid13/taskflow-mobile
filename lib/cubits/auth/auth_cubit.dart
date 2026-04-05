import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/error_handler.dart';
import '../../core/secure_storage.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  final UserService _userService;

  AuthCubit({
    AuthService? authService,
    UserService? userService,
  })  : _authService = authService ?? AuthService(),
        _userService = userService ?? UserService(),
        super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final loginResponse = await _authService.login(email, password);
      await SecureStorage.setToken(loginResponse.accessToken);

      // Decode JWT to get user ID from 'sub' claim
      final userId = _extractUserIdFromToken(loginResponse.accessToken);
      await SecureStorage.setUserId(userId.toString());

      final user = await _userService.getUser(userId);
      emit(Authenticated(user: user, token: loginResponse.accessToken));
    } catch (e) {
      emit(AuthError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> signup(String email, String password, String fullName) async {
    emit(AuthLoading());
    try {
      await _authService.signup(email, password, fullName);
      // Auto-login after successful signup
      await login(email, password);
    } catch (e) {
      emit(AuthError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> restoreSession() async {
    final token = await SecureStorage.getToken();
    final userIdStr = await SecureStorage.getUserId();

    if (token == null || userIdStr == null) {
      emit(Unauthenticated());
      return;
    }

    try {
      final userId = int.parse(userIdStr);
      final user = await _userService.getUser(userId);
      emit(Authenticated(user: user, token: token));
    } catch (_) {
      await SecureStorage.clearAll();
      emit(Unauthenticated());
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearAll();
    emit(Unauthenticated());
  }

  int _extractUserIdFromToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw const FormatException('Invalid JWT');
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final map = json.decode(decoded) as Map<String, dynamic>;
    return int.parse(map['sub'].toString());
  }
}
