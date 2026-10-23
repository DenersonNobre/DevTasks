// solution/app/lib/modules/auth/domain/email.dart
// Value Object de e-mail (UC-01.01).
// SRP: normalizar e validar o formato de um e-mail, expondo o valor canônico.
// NÃO faz: persistência, checagem de unicidade (INV-08 vive na camada de aplicação),
// envio de mensagens, I/O, nem depende de Flutter/Serverpod.

import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/result.dart';

/// E-mail imutável, sempre normalizado (trim + minúsculas).
final class Email {
  static final RegExp _format = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Valor canônico: sem espaços nas extremidades e em minúsculas.
  final String value;

  const Email._(this.value);

  /// Normaliza [input] e valida o formato simples (`local@dominio.tld`).
  static IResult<Email, ValidationFailure> parse(String input) {
    final normalized = input.trim().toLowerCase();

    if (normalized.isEmpty) {
      return Failure(const ValidationFailure('E-mail é obrigatório.', 'email'));
    }

    if (!_format.hasMatch(normalized)) {
      return Failure(const ValidationFailure('E-mail inválido.', 'email'));
    }

    return Success(Email._(normalized));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Email && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
