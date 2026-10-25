/// As 3 colunas fechadas do Kanban (D-01 / INV-04 / SPEC §4.2).
enum TaskStatus {
  backlog('backlog'),
  inProgress('in_progress'),
  done('done');

  const TaskStatus(this.value);

  final String value;

  static TaskStatus? fromString(String? raw) {
    if (raw == null) return null;
    for (final s in values) {
      if (s.value == raw) return s;
    }
    return null;
  }
}
