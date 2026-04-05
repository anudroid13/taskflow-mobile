import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/task_detail/task_detail_cubit.dart';
import '../../cubits/task_detail/task_detail_state.dart';
import '../../models/task.dart';
import '../../models/user.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/priority_tag.dart';
import '../../widgets/status_badge.dart';
import '../../services/task_service.dart';

class TaskDetailView extends StatefulWidget {
  final int taskId;

  const TaskDetailView({super.key, required this.taskId});

  @override
  State<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  @override
  void initState() {
    super.initState();
    context.read<TaskDetailCubit>().loadTask(widget.taskId);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final currentUser = authState is Authenticated ? authState.user : null;
    final isAdminOrManager = currentUser != null &&
        (currentUser.role == UserRole.admin ||
            currentUser.role == UserRole.manager);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          if (isAdminOrManager)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/tasks/${widget.taskId}/edit'),
            ),
          if (currentUser?.role == UserRole.admin)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteTask(context),
            ),
        ],
      ),
      body: BlocBuilder<TaskDetailCubit, TaskDetailState>(
        builder: (context, state) {
          if (state is TaskDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TaskDetailError) {
            return Center(child: Text(state.message));
          }

          Task? task;
          List<dynamic> attachments = [];
          double? uploadProgress;

          if (state is TaskDetailLoaded) {
            task = state.task;
            attachments = state.attachments;
          } else if (state is TaskDetailUploading) {
            task = state.task;
            attachments = state.attachments;
            uploadProgress = state.progress;
          }

          if (task == null) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<TaskDetailCubit>().loadTask(widget.taskId),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Status & Priority row
                  Row(
                    children: [
                      StatusBadge(status: task.status),
                      const SizedBox(width: 8),
                      PriorityTag(priority: task.priority),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  if (task.description != null &&
                      task.description!.isNotEmpty) ...[
                    Text('Description',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(task.description!),
                    const SizedBox(height: 16),
                  ],

                  // Status transitions
                  if (task.validTransitions.isNotEmpty) ...[
                    Text('Update Status',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: task.validTransitions
                          .map((s) => ActionChip(
                                label: Text(s.name),
                                onPressed: () => context
                                    .read<TaskDetailCubit>()
                                    .updateStatus(task!.id, s.name),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Upload progress
                  if (uploadProgress != null) ...[
                    LinearProgressIndicator(value: uploadProgress),
                    const SizedBox(height: 8),
                    Text(
                      'Uploading... ${(uploadProgress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Attachments section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Attachments (${attachments.length})',
                          style: Theme.of(context).textTheme.titleSmall),
                      IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: uploadProgress != null
                            ? null
                            : () => _pickAndUploadFile(context),
                      ),
                    ],
                  ),
                  if (attachments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No attachments',
                          style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ...attachments.map((a) => ListTile(
                          leading: const Icon(Icons.insert_drive_file),
                          title: Text(a.filename),
                          dense: true,
                        )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickAndUploadFile(BuildContext context) async {
    final result = await FilePicker.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;
    if (mounted) {
      context
          .read<TaskDetailCubit>()
          .uploadFile(widget.taskId, file.path!, file.name);
    }
  }

  Future<void> _deleteTask(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Task',
      content: 'Are you sure you want to delete this task?',
    );
    if (confirmed && mounted) {
      await TaskService().deleteTask(widget.taskId);
      if (mounted) context.pop();
    }
  }
}
