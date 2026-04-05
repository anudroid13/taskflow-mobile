import 'package:flutter/material.dart';
import '../../models/task.dart';

class PriorityTag extends StatelessWidget {
  final TaskPriority priority;

  const PriorityTag({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color get _color {
    switch (priority) {
      case TaskPriority.low:
        return Colors.teal;
      case TaskPriority.medium:
        return Colors.amber.shade700;
      case TaskPriority.high:
        return Colors.red;
    }
  }
}
