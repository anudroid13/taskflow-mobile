import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/error_handler.dart';
import '../../models/attachment.dart';
import '../../services/attachment_service.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';
import 'task_detail_state.dart';

class TaskDetailCubit extends Cubit<TaskDetailState> {
  final TaskService _taskService;
  final AttachmentService _attachmentService;
  final UserService _userService;

  TaskDetailCubit({
    TaskService? taskService,
    AttachmentService? attachmentService,
    UserService? userService,
  })  : _taskService = taskService ?? TaskService(),
        _attachmentService = attachmentService ?? AttachmentService(),
        _userService = userService ?? UserService(),
        super(TaskDetailInitial());

  Future<void> loadTask(int taskId) async {
    emit(TaskDetailLoading());
    try {
      final task = await _taskService.getTask(taskId);
      final attachments = await _attachmentService.getAttachments();
      final taskAttachments =
          attachments.where((a) => a.taskId == taskId).toList();
      final owner = await _userService.getUser(task.ownerId);
      emit(TaskDetailLoaded(task: task, attachments: taskAttachments, owner: owner));
    } catch (e) {
      emit(TaskDetailError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> updateStatus(int taskId, String newStatus) async {
    try {
      final task = await _taskService.updateTask(taskId, {'status': newStatus});
      final currentState = state;
      final attachments = currentState is TaskDetailLoaded
          ? currentState.attachments
          : <Attachment>[];
      emit(TaskDetailLoaded(task: task, attachments: attachments));
    } catch (e) {
      emit(TaskDetailError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> uploadFile(int taskId, String filePath, String fileName) async {
    final currentState = state;
    if (currentState is! TaskDetailLoaded) return;

    emit(TaskDetailUploading(
      task: currentState.task,
      attachments: currentState.attachments,
      progress: 0,
    ));

    try {
      final attachment = await _attachmentService.uploadFile(
        filePath,
        fileName,
        taskId,
        onSendProgress: (sent, total) {
          if (total > 0) {
            emit(TaskDetailUploading(
              task: currentState.task,
              attachments: currentState.attachments,
              progress: sent / total,
            ));
          }
        },
      );

      final updatedAttachments = [...currentState.attachments, attachment];
      emit(TaskDetailLoaded(
        task: currentState.task,
        attachments: updatedAttachments,
      ));
    } catch (e) {
      emit(TaskDetailError(ErrorHandler.getMessage(e)));
    }
  }
}
