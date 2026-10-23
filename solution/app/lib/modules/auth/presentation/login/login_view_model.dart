import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:devtasks_app/global/kernel/.kernel.dart';
import 'package:devtasks_app/global/session/.session.dart';
import 'package:devtasks_app/modules/auth/domain/.domain.dart';
import 'package:devtasks_app/modules/auth/infrastructure/.infrastructure.dart';
import 'package:devtasks_app/modules/auth/presentation/.presentation.dart';
import 'package:devtasks_app/modules/auth/presentation/auth_failure_message.dart';

/// ViewModel do login (D-07): valida com os VOs, chama a porta e delega a
/// persistência da sessão ao estado transversal (`global/`).
/// Puro: sem `BuildContext`, sem I/O próprio (portas injetadas via Riverpod).
final loginViewModelProvider =
    NotifierProvider<LoginViewModel, LoginState>(LoginViewModel.new);

final class LoginViewModel extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  /// Intent de submissão do formulário.
  Future<void> submit({required String rawEmail, required String rawPassword}) async {
    final email = Email.parse(rawEmail);
    final password = Password.parse(rawPassword);
    final validEmail = email.valueOrNull;
    final validPassword = password.valueOrNull;

    if (validEmail == null || validPassword == null) {
      state = LoginState(
        emailError: email.failureOrNull?.message,
        passwordError: password.failureOrNull?.message,
      );
      return;
    }

    state = const LoginState(status: AuthFormStatus.loading);
    final result = await ref.read(authClientProvider).signIn(
          email: validEmail.value,
          password: validPassword.value,
        );

    switch (result) {
      case Failure(:final failure):
        state = LoginState(
          status: AuthFormStatus.error,
          message: authFailureMessage(failure),
        );
        return;
      case Success(:final value):
        await ref.read(sessionControllerProvider).signIn(value.token);
        state = const LoginState(status: AuthFormStatus.completed);
    }
  }
}
