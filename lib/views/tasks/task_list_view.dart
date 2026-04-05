import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/task_list/task_list_cubit.dart';
import '../../cubits/task_list/task_list_state.dart';
import '../../models/task.dart';
import '../../models/user.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/priority_tag.dart';
import '../../widgets/status_badge.dart';

class TaskListView extends StatefulWidget {
  const TaskListView({super.key});

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  TaskStatus? _statusFilter;
  TaskPriority? _priorityFilter;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    final authState = context.read<AuthCubit>().state;
    int? ownerId;
    if (authState is Authenticated && authState.user.role == UserRole.employee) {
      ownerId = authState.user.id;
    }
    context.read<TaskListCubit>().fetchTasks(
          statusFilter: _statusFilter?.name,
          priority: _priorityFilter?.name,
          ownerId: ownerId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final isEmployee =
        authState is Authenticated && authState.user.role == UserRole.employee;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEmployee ? 'My Tasks' : 'Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/tasks/create'),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadTasks(),
        child: BlocBuilder<TaskListCubit, TaskListState>(
          builder: (context, state) {
            if (state is TaskListLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is TaskListError) {
              return Center(child: Text(state.message));
            }
            if (state is TaskListLoaded) {
              if (state.tasks.isEmpty) {
                return const EmptyState(message: 'No tasks yet');
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: state.tasks.length,
                itemBuilder: (context, index) {
                  final task = state.tasks[index];
                  return _TaskCard(task: task);
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter by Status',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _statusFilter == null,
                  onSelected: (_) => _applyStatusFilter(null),
                ),
                ...TaskStatus.values.map((s) => FilterChip(
                      label: Text(s.name),
                      selected: _statusFilter == s,
                      onSelected: (_) => _applyStatusFilter(s),
                    )),
              ],
            ),
            const SizedBox(height: 16),
            Text('Filter by Priority',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _priorityFilter == null,
                  onSelected: (_) => _applyPriorityFilter(null),
                ),
                ...TaskPriority.values.map((p) => FilterChip(
                      label: Text(p.name),
                      selected: _priorityFilter == p,
                      onSelected: (_) => _applyPriorityFilter(p),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _applyStatusFilter(TaskStatus? status) {
    Navigator.of(context).pop();
    setState(() => _statusFilter = status);
    _loadTasks();
  }

  void _applyPriorityFilter(TaskPriority? priority) {
    Navigator.of(context).pop();
    setState(() => _priorityFilter = priority);
    _loadTasks();
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          task.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              StatusBadge(status: task.status),
              const SizedBox(width: 8),
              PriorityTag(priority: task.priority),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/tasks/${task.id}'),
      ),
    );
  }
}
