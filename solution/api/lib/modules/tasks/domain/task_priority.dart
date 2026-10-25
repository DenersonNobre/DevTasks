/// Prioridade de tarefas (SPEC §4.2 / RF-09).
enum TaskPriority {
  low('low'),
  medium('medium'),
  high('high');

  const TaskPriority(this.value);

  final String value;

  static TaskPriority? fromString(String raw) {
    for (final p in values) {
      if (p.value == raw) return p;
    }
    return null;
  }
}
