import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/task_form/task_form_cubit.dart';
import '../../cubits/task_form/task_form_state.dart';
import '../../models/task.dart';
import '../../models/user.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';

class TaskEditView extends StatefulWidget {
  final int taskId;

  const TaskEditView({super.key, required this.taskId});

  @override
  State<TaskEditView> createState() => _TaskEditViewState();
}

class _TaskEditViewState extends State<TaskEditView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  TaskStatus _status = TaskStatus.todo;
  bool _isLoading = true;
  Task? _task;
  List<User> _users = [];
  int? _selectedOwnerId;
  bool _isAdminOrManager = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRole();
      _loadTask();
    });
  }

  void _checkRole() {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated &&
        (authState.user.role == UserRole.admin ||
            authState.user.role == UserRole.manager)) {
      _isAdminOrManager = true;
      _loadUsers();
    }
  }

  Future<void> _loadUsers() async {
    final users = await UserService().getUsers();
    if (mounted) setState(() => _users = users);
  }

  Future<void> _loadTask() async {
    try {
      final task = await TaskService().getTask(widget.taskId);
      setState(() {
        _task = task;
        _titleController.text = task.title;
        _descriptionController.text = task.description ?? '';
        _priority = task.priority;
        _status = task.status;
        _selectedOwnerId = task.ownerId;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load task')),
        );
        context.pop();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final data = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'priority': _priority.name,
    };
    if (_status != _task?.status) {
      data['status'] = _status.name;
    }
    if (_isAdminOrManager && _selectedOwnerId != null) {
      data['owner_id'] = _selectedOwnerId;
    }
    context.read<TaskFormCubit>().updateTask(widget.taskId, data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Task')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : BlocListener<TaskFormCubit, TaskFormState>(
              listener: (context, state) {
                if (state is TaskFormSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task updated successfully')),
                  );
                  context.pop();
                } else if (state is TaskFormError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red),
                  );
                }
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<TaskPriority>(
                        value: _priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                        ),
                        items: TaskPriority.values
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p.name.toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _priority = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<TaskStatus>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: <TaskStatus>{
                          _status,
                          ..._task?.validTransitions ?? [],
                        }
                            .map((s) => DropdownMenuItem<TaskStatus>(
                                  value: s,
                                  child: Text(s.name),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _status = value);
                        },
                      ),
                      if (_isAdminOrManager && _users.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: _selectedOwnerId,
                          decoration: const InputDecoration(
                            labelText: 'Assign To',
                            border: OutlineInputBorder(),
                          ),
                          items: _users
                              .map((u) => DropdownMenuItem(
                                    value: u.id,
                                    child: Text('${u.fullName} (${u.email})'),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedOwnerId = value);
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                      BlocBuilder<TaskFormCubit, TaskFormState>(
                        builder: (context, state) {
                          final isSubmitting = state is TaskFormLoading;
                          return FilledButton(
                            onPressed: isSubmitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Save Changes',
                                    style: TextStyle(fontSize: 16)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
