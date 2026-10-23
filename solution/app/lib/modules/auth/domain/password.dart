// solution/app/lib/modules/auth/domain/password.dart
// Value Object de senha (UC-01.01).
// SRP: validar a política de senha (12..128, minúscula, maiúscula, dígito) e
// carregar o segredo sem jamais expô-lo em representação textual.
// NÃO faz: hash, persistência, comparação de credenciais, I/O, nem depende de
// Flutter/Serverpod.

import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/result.dart';

/// Senha em texto claro, imutável e com representação textual mascarada.
final class Password {
  static const int minLength = 12;
  static const int maxLength = 128;

  static final RegExp _hasLowercase = RegExp('[a-z]');
  static final RegExp _hasUppercase = RegExp('[A-Z]');
  static final RegExp _hasDigit = RegExp('[0-9]');

  /// Segredo original; nunca deve ser logado nem serializado.
  final String value;

  const Password._(this.value);

  /// Valida [input] contra a política de senha, uma violação por vez.
  static IResult<Password, ValidationFailure> parse(String input) {
    if (input.length < minLength) {
      return Failure(
        const ValidationFailure(
          'A senha deve ter no mínimo $minLength caracteres.',
          'password',
        ),
      );
    }

    if (input.length > maxLength) {
      return Failure(
        const ValidationFailure(
          'A senha deve ter no máximo $maxLength caracteres.',
          'password',
        ),
      );
    }

    if (!_hasLowercase.hasMatch(input)) {
      return Failure(
        const ValidationFailure(
          'A senha deve conter ao menos uma letra minúscula.',
          'password',
        ),
      );
    }

    if (!_hasUppercase.hasMatch(input)) {
      return Failure(
        const ValidationFailure(
          'A senha deve conter ao menos uma letra maiúscula.',
          'password',
        ),
      );
    }

    if (!_hasDigit.hasMatch(input)) {
      return Failure(
        const ValidationFailure(
          'A senha deve conter ao menos um dígito.',
          'password',
        ),
      );
    }

    return Success(Password._(input));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Password && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Password(***)';
}
