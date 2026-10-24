/// Value Object imutável para o nome do Workspace (SPEC §4.2).
///
/// Regras de negócio:
/// - Não pode ser vazio ou composto apenas de espaços;
/// - Comprimento máximo: 100 caracteres;
/// - Normalizado com trim.
class WorkspaceName {
  WorkspaceName._(this.value);

  final String value;

  static (WorkspaceName?, String?) create(String? raw) {
    if (raw == null) {
      return (null, 'Nome do workspace é obrigatório.');
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return (null, 'Nome do workspace não pode ser vazio.');
    }
    if (trimmed.length > 100) {
      return (null, 'Nome do workspace deve ter no máximo 100 caracteres.');
    }
    return (WorkspaceName._(trimmed), null);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkspaceName && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}