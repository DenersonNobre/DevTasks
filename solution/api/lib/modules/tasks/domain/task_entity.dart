import 'task_priority.dart';
import 'task_status.dart';

/// Agregado/Entidade de Tarefa no backend (EPIC-04 · SPEC §4.1 / RF-09).
class TaskEntity {
  const TaskEntity({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    required this.position,
    this.assignedUserId,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
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
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'description': description,
        'status': status.value,
        'priority': priority.value,
        'position': position,
        'assignedUserId': assignedUserId,
        'dueDate': dueDate != null
            ? '${dueDate!.year.toString().padLeft(4, '0')}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}'
            : null,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };
}
