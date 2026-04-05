import 'package:equatable/equatable.dart';

class Attachment extends Equatable {
  final int id;
  final String filename;
  final String url;
  final int taskId;
  final int uploaderId;
  final DateTime uploadedAt;

  const Attachment({
    required this.id,
    required this.filename,
    required this.url,
    required this.taskId,
    required this.uploaderId,
    required this.uploadedAt,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as int,
      filename: json['filename'] as String,
      url: json['url'] as String,
      taskId: json['task_id'] as int,
      uploaderId: json['uploader_id'] as int,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'url': url,
      'task_id': taskId,
    };
  }

  @override
  List<Object?> get props => [id, filename, url, taskId, uploaderId, uploadedAt];
}
