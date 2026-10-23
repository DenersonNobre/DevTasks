import 'package:flutter/foundation.dart';

import 'package:devtasks_app/modules/auth/domain/auth_client.dart';
import 'package:devtasks_app/modules/auth/presentation/auth_form_status.dart';

/// Estado imutável da tela de login (D-07: estado + intents).
///
/// Erros de campo vêm dos VOs (`Email`/`Password`); [message] é o erro de
/// formulário (credencial inválida, falha de infra) com mensagem única.
@immutable
final class LoginState {
  const LoginState({
    this.status = AuthFormStatus.idle,
    this.emailError,
    this.passwordError,
    this.message,
    this.session,
  });

  final AuthFormStatus status;
  final String? emailError;
  final String? passwordError;
  final String? message;
  final AuthSession? session;

  bool get isLoading => status == AuthFormStatus.loading;
  bool get isCompleted => status == AuthFormStatus.completed;
}
