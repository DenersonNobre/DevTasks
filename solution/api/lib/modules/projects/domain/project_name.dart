/// Value Object do nome de projeto (UC-03.01).
///
/// SRP: valida formato e normaliza (trim) — não persiste nem autoriza.
/// Regras: obrigatório, não-branco, até 100 caracteres.
class ProjectName {
  const ProjectName._(this.value);

  final String value;

  static const int maxLength = 100;

  /// Cria um [ProjectName] válido ou devolve a mensagem de erro.
  static ({ProjectName? name, String? error}) parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return (name: null, error: 'O nome do projeto é obrigatório.');
    }
    if (trimmed.length > maxLength) {
      return (
        name: null,
        error: 'O nome do projeto deve ter até $maxLength caracteres.',
      );
    }
    return (name: ProjectName._(trimmed), error: null);
  }
}