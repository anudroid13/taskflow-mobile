import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/task.dart';

class TaskService {
  final Dio _dio = ApiClient().dio;

  Future<List<Task>> getTasks({
    int skip = 0,
    int limit = 100,
    String? statusFilter,
    String? priority,
    int? ownerId,
    String? createdAfter,
    String? createdBefore,
  }) async {
    final params = <String, dynamic>{'skip': skip, 'limit': limit};
    if (statusFilter != null) params['status_filter'] = statusFilter;
    if (priority != null) params['priority'] = priority;
    if (ownerId != null) params['owner_id'] = ownerId;
    if (createdAfter != null) params['created_after'] = createdAfter;
    if (createdBefore != null) params['created_before'] = createdBefore;

    final response = await _dio.get('/tasks/', queryParameters: params);
    return (response.data as List).map((e) => Task.fromJson(e)).toList();
  }

  Future<Task> getTask(int id) async {
    final response = await _dio.get('/tasks/$id');
    return Task.fromJson(response.data);
  }

  Future<Task> createTask({
    required String title,
    String? description,
    String? status,
    String? priority,
    required int ownerId,
  }) async {
    final data = <String, dynamic>{
      'title': title,
      'owner_id': ownerId,
    };
    if (description != null) data['description'] = description;
    if (status != null) data['status'] = status;
    if (priority != null) data['priority'] = priority;

    final response = await _dio.post('/tasks/', data: data);
    return Task.fromJson(response.data);
  }

  Future<Task> updateTask(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/tasks/$id', data: data);
    return Task.fromJson(response.data);
  }

  Future<Task> assignTask(int taskId, int ownerId) async {
    final response = await _dio.patch(
      '/tasks/$taskId/assign',
      data: {'owner_id': ownerId},
    );
    return Task.fromJson(response.data);
  }

  Future<void> deleteTask(int id) async {
    await _dio.delete('/tasks/$id');
  }
}
