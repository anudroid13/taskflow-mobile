import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/error_handler.dart';
import '../../services/task_service.dart';
import 'task_list_state.dart';

class TaskListCubit extends Cubit<TaskListState> {
  final TaskService _taskService;

  TaskListCubit({TaskService? taskService})
      : _taskService = taskService ?? TaskService(),
        super(TaskListInitial());

  Future<void> fetchTasks({
    String? statusFilter,
    String? priority,
    int? ownerId,
    String? createdAfter,
    String? createdBefore,
  }) async {
    emit(TaskListLoading());
    try {
      final tasks = await _taskService.getTasks(
        statusFilter: statusFilter,
        priority: priority,
        ownerId: ownerId,
        createdAfter: createdAfter,
        createdBefore: createdBefore,
      );
      emit(TaskListLoaded(tasks));
    } catch (e) {
      emit(TaskListError(ErrorHandler.getMessage(e)));
    }
  }
}
