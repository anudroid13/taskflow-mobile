import 'package:flutter/material.dart';
import '../../models/task.dart';

class StatusBadge extends StatelessWidget {
  final TaskStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String get _label {
    switch (status) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.in_progress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
      case TaskStatus.overdue:
        return 'Overdue';
    }
  }

  Color get _color {
    switch (status) {
      case TaskStatus.todo:
        return Colors.blue;
      case TaskStatus.in_progress:
        return Colors.orange;
      case TaskStatus.done:
        return Colors.green;
      case TaskStatus.overdue:
        return Colors.red;
    }
  }
}
