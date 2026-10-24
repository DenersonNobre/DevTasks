/// Value Object de e-mail no servidor (UC-01.04 / DRY).
///
/// Responsabilidade única: normalizar e validar formato de e-mail.
final class Email {
  const Email._(this.value);

  static final RegExp _format = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Valor canônico normalizado (sem espaços nas extremidades e em minúsculas).
  final String value;

  /// Normaliza [input] e valida formato. Retorna o [Email] ou mensagem de erro.
  static ({Email? email, String? error}) parse(String input) {
    final normalized = input.trim().toLowerCase();

    if (normalized.isEmpty) {
      return (email: null, error: 'E-mail é obrigatório.');
    }

    if (!_format.hasMatch(normalized)) {
      return (email: null, error: 'E-mail inválido.');
    }

    return (email: Email._(normalized), error: null);
  }

  /// Retorna `true` se o e-mail tem formato estruturalmente válido.
  static bool isValid(String input) {
    final normalized = input.trim().toLowerCase();
    return normalized.isNotEmpty && _format.hasMatch(normalized);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Email && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Email(***)';
}

