// solution/app/lib/modules/tasks/domain/task_status.dart
// Status fechados de uma tarefa no Kanban (D-01 / INV-04).

/// Status de tarefa no Kanban.
enum TaskStatus {
  backlog('backlog', 'Backlog'),
  inProgress('in_progress', 'Em Progresso'),
  done('done', 'Concluído');

  const TaskStatus(this.value, this.label);

  final String value;
  final String label;

  static TaskStatus? fromString(String? text) {
    if (text == null) return null;
    final normalized = text.trim().toLowerCase();
    for (final status in values) {
      if (status.value == normalized || status.name.toLowerCase() == normalized) {
        return status;
      }
    }
    return null;
  }
}
