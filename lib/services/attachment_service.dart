import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/attachment.dart';

class AttachmentService {
  final Dio _dio = ApiClient().dio;

  Future<Attachment> uploadFile(
    String filePath,
    String fileName,
    int taskId, {
    void Function(int, int)? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'task_id': taskId,
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _dio.post(
      '/attachments/upload',
      data: formData,
      onSendProgress: onSendProgress,
    );
    return Attachment.fromJson(response.data);
  }

  Future<List<Attachment>> getAttachments({
    int skip = 0,
    int limit = 100,
  }) async {
    final response = await _dio.get(
      '/attachments/',
      queryParameters: {'skip': skip, 'limit': limit},
    );
    return (response.data as List)
        .map((e) => Attachment.fromJson(e))
        .toList();
  }

  Future<Attachment> getAttachment(int id) async {
    final response = await _dio.get('/attachments/$id');
    return Attachment.fromJson(response.data);
  }

  Future<Attachment> updateAttachment(int id, String filename) async {
    final response = await _dio.put(
      '/attachments/$id',
      data: {'filename': filename},
    );
    return Attachment.fromJson(response.data);
  }

  Future<void> deleteAttachment(int id) async {
    await _dio.delete('/attachments/$id');
  }
}
