import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/user.dart';

class UserService {
  final Dio _dio = ApiClient().dio;

  Future<List<User>> getUsers({
    int skip = 0,
    int limit = 100,
    String? role,
    String? email,
  }) async {
    final params = <String, dynamic>{'skip': skip, 'limit': limit};
    if (role != null) params['role'] = role;
    if (email != null) params['email'] = email;

    final response = await _dio.get('/users/', queryParameters: params);
    return (response.data as List).map((e) => User.fromJson(e)).toList();
  }

  Future<User> getUser(int id) async {
    final response = await _dio.get('/users/$id');
    return User.fromJson(response.data);
  }

  Future<User> createUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
    bool isActive = true,
  }) async {
    final response = await _dio.post('/users/', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
      'role': role,
      'is_active': isActive,
    });
    return User.fromJson(response.data);
  }

  Future<User> updateUser(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/users/$id', data: data);
    return User.fromJson(response.data);
  }

  Future<void> deleteUser(int id) async {
    await _dio.delete('/users/$id');
  }
}
