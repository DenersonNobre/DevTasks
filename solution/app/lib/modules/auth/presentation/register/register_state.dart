import 'package:flutter/foundation.dart';

import 'package:devtasks_app/modules/auth/presentation/auth_form_status.dart';

/// Estado imutável da tela de cadastro (D-07: estado + intents).
@immutable
final class RegisterState {
  const RegisterState({
    this.status = AuthFormStatus.idle,
    this.nameError,
    this.emailError,
    this.passwordError,
    this.message,
    this.userId,
  });

  final AuthFormStatus status;
  final String? nameError;
  final String? emailError;
  final String? passwordError;
  final String? message;

  /// Id do usuário criado (o contrato de cadastro não emite token).
  final String? userId;

  bool get isLoading => status == AuthFormStatus.loading;
  bool get isCompleted => status == AuthFormStatus.completed;
}
