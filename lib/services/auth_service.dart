import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/login_response.dart';
import '../models/user.dart';

class AuthService {
  final Dio _dio = ApiClient().dio;

  Future<LoginResponse> login(String email, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return LoginResponse.fromJson(response.data);
  }

  Future<User> signup(String email, String password, String fullName) async {
    final response = await _dio.post(
      '/auth/signup',
      data: {
        'email': email,
        'password': password,
        'full_name': fullName,
      },
    );
    return User.fromJson(response.data);
  }
}
