/// Valida e encapsula o título de uma tarefa (SPEC §4.2 / RF-09).
///
/// Não vazio, no máximo 120 caracteres.
class TaskTitle {
  const TaskTitle._(this.value);

  final String value;

  static ({TaskTitle? title, String? error}) parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return (title: null, error: 'O título da tarefa é obrigatório.');
    }
    if (trimmed.length > 120) {
      return (
        title: null,
        error: 'O título da tarefa não pode exceder 120 caracteres.',
      );
    }
    return (title: TaskTitle._(trimmed), error: null);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TaskTitle && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
