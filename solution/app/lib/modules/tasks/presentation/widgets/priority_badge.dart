// solution/app/lib/modules/tasks/presentation/widgets/priority_badge.dart
// Badge visual com contraste acessível para prioridade de tarefas (UC-04.01).

import 'package:flutter/material.dart';

import '../../domain/task_priority.dart';

/// Badge visual para indicar a prioridade de uma tarefa com alto contraste.
class PriorityBadge extends StatelessWidget {
  const PriorityBadge({
    super.key,
    required this.priority,
  });

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final (Color background, Color foreground, Color border) = switch (priority) {
      TaskPriority.high => isDark
          ? (const Color(0xFF5C1D1D), const Color(0xFFFFB4AB), const Color(0xFF93000A))
          : (const Color(0xFFFFDAD6), const Color(0xFF410002), const Color(0xFFBA1A1A)),
      TaskPriority.medium => isDark
          ? (const Color(0xFF534300), const Color(0xFFFFE088), const Color(0xFF715C00))
          : (const Color(0xFFFFE08B), const Color(0xFF241A00), const Color(0xFF8E7300)),
      TaskPriority.low => isDark
          ? (const Color(0xFF1B4D3E), const Color(0xFF8BF3D0), const Color(0xFF006C4C))
          : (const Color(0xFFC7F3E3), const Color(0xFF003826), const Color(0xFF008760)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
