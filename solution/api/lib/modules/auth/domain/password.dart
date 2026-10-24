/// Validador estático da política de complexidade de senha no servidor (UC-01.04 / INV-SEC-08 / DRY).
///
/// Política de complexidade canônica:
/// - Tamanho: entre 12 e 128 caracteres.
/// - Letra minúscula obrigatória.
/// - Letra maiúscula obrigatória.
/// - Dígito decimal obrigatório.
abstract final class Password {
  static const int minLength = 12;
  static const int maxLength = 128;

  static final RegExp _hasLower = RegExp('[a-z]');
  static final RegExp _hasUpper = RegExp('[A-Z]');
  static final RegExp _hasDigit = RegExp('[0-9]');

  /// Valida [password] contra a política de complexidade.
  /// Retorna `null` se válida, ou a mensagem de violação.
  static String? validate(String password) {
    if (password.length < minLength) {
      return 'A senha deve ter ao menos $minLength caracteres.';
    }
    if (password.length > maxLength) {
      return 'A senha deve ter no máximo $maxLength caracteres.';
    }
    if (!_hasLower.hasMatch(password)) {
      return 'A senha deve conter ao menos uma letra minúscula.';
    }
    if (!_hasUpper.hasMatch(password)) {
      return 'A senha deve conter ao menos uma letra maiúscula.';
    }
    if (!_hasDigit.hasMatch(password)) {
      return 'A senha deve conter ao menos um dígito.';
    }
    return null;
  }
}
