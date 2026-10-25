// solution/app/lib/modules/tasks/domain/task_priority.dart
// Prioridades de tarefa no DevTasks (SPEC §3 / RF-09).

/// Nível de prioridade de uma tarefa.
enum TaskPriority {
  low('low', 'Baixa'),
  medium('medium', 'Média'),
  high('high', 'Alta');

  const TaskPriority(this.value, this.label);

  final String value;
  final String label;

  static TaskPriority? fromString(String? text) {
    if (text == null) return null;
    final normalized = text.trim().toLowerCase();
    for (final priority in values) {
      if (priority.value == normalized || priority.name.toLowerCase() == normalized) {
        return priority;
      }
    }
    return null;
  }
}
