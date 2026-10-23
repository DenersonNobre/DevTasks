import 'package:flutter/foundation.dart';

import 'package:devtasks_app/modules/auth/presentation/auth_form_status.dart';

/// Estado imutável da tela de login (D-07: estado + intents).
///
/// Não carrega o token: a sessão é estado **transversal** (global/) e o slice
/// apenas observa. Erros de campo vêm dos VOs; [message] é o erro de formulário.
@immutable
final class LoginState {
  const LoginState({
    this.status = AuthFormStatus.idle,
    this.emailError,
    this.passwordError,
    this.message,
  });

  final AuthFormStatus status;
  final String? emailError;
  final String? passwordError;
  final String? message;

  bool get isLoading => status == AuthFormStatus.loading;
  bool get isCompleted => status == AuthFormStatus.completed;
}
