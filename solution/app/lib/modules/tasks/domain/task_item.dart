// solution/app/lib/modules/tasks/domain/task_item.dart
// VO / Entidade imutável de Tarefa no app (D-07 / UC-04.01).
// SRP: representar uma tarefa exibível e editável.
// IDs são UUID (String) — contrato OpenAPI (D-08).

import 'package:flutter/foundation.dart';

import 'task_priority.dart';
import 'task_status.dart';

/// Tarefa exibível no Kanban e listas do projeto.
@immutable
final class TaskItem {
  const TaskItem({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    this.status = TaskStatus.backlog,
    this.priority = TaskPriority.medium,
    this.position = 0.0,
    this.assignedUserId,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String projectId;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final double position;
  final String? assignedUserId;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TaskItem copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    bool clearDescription = false,
    TaskStatus? status,
    TaskPriority? priority,
    double? position,
    String? assignedUserId,
    bool clearAssignedUser = false,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      status: status ?? this.status,
      priority: priority ?? this.priority,
      position: position ?? this.position,
      assignedUserId:
          clearAssignedUser ? null : (assignedUserId ?? this.assignedUserId),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskItem &&
          id == other.id &&
          projectId == other.projectId &&
          title == other.title &&
          description == other.description &&
          status == other.status &&
          priority == other.priority &&
          position == other.position &&
          assignedUserId == other.assignedUserId &&
          dueDate == other.dueDate &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        projectId,
        title,
        description,
        status,
        priority,
        position,
        assignedUserId,
        dueDate,
        createdAt,
        updatedAt,
      );
}
