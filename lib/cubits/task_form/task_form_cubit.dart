import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/error_handler.dart';
import '../../services/task_service.dart';
import 'task_form_state.dart';

class TaskFormCubit extends Cubit<TaskFormState> {
  final TaskService _taskService;

  TaskFormCubit({TaskService? taskService})
      : _taskService = taskService ?? TaskService(),
        super(TaskFormInitial());

  Future<void> createTask({
    required String title,
    String? description,
    String? priority,
    required int ownerId,
  }) async {
    emit(TaskFormLoading());
    try {
      await _taskService.createTask(
        title: title,
        description: description,
        priority: priority,
        ownerId: ownerId,
      );
      emit(TaskFormSuccess());
    } catch (e) {
      emit(TaskFormError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> updateTask(int taskId, Map<String, dynamic> data) async {
    emit(TaskFormLoading());
    try {
      await _taskService.updateTask(taskId, data);
      emit(TaskFormSuccess());
    } catch (e) {
      emit(TaskFormError(ErrorHandler.getMessage(e)));
    }
  }

  Future<void> assignTask(int taskId, int ownerId) async {
    emit(TaskFormLoading());
    try {
      await _taskService.assignTask(taskId, ownerId);
      emit(TaskFormSuccess());
    } catch (e) {
      emit(TaskFormError(ErrorHandler.getMessage(e)));
    }
  }
}
