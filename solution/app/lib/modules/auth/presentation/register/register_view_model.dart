import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:devtasks_app/global/kernel/.kernel.dart';
import 'package:devtasks_app/modules/auth/.domain.dart';
import 'package:devtasks_app/modules/auth/.infrastructure.dart';
import 'package:devtasks_app/modules/auth/.presentation.dart';

/// ViewModel do cadastro (D-07): valida com VOs, chama a porta e conclui.
/// Puro: sem `BuildContext`, sem I/O próprio.
final registerViewModelProvider =
    NotifierProvider<RegisterViewModel, RegisterState>(RegisterViewModel.new);

final class RegisterViewModel extends Notifier<RegisterState> {
  @override
  RegisterState build() => const RegisterState();

  /// Intent de submissão do formulário de cadastro.
  Future<void> submit({
    required String rawName,
    required String rawEmail,
    required String rawPassword,
  }) async {
    final name = NonEmptyString.create(rawName, 'nome');
    final email = Email.parse(rawEmail);
    final password = Password.parse(rawPassword);
    final validName = name.valueOrNull;
    final validEmail = email.valueOrNull;
    final validPassword = password.valueOrNull;

    if (validName == null || validEmail == null || validPassword == null) {
      state = RegisterState(
        nameError: name.failureOrNull?.message,
        emailError: email.failureOrNull?.message,
        passwordError: password.failureOrNull?.message,
      );
      return;
    }

    state = const RegisterState(status: AuthFormStatus.loading);
    final result = await ref.read(authClientProvider).signUp(
          name: validName.value,
          email: validEmail.value,
          password: validPassword.value,
        );

    switch (result) {
      case Failure(:final failure):
        state = RegisterState(status: AuthFormStatus.error, message: failure.message);
        return;
      case Success(:final value):
        state = RegisterState(status: AuthFormStatus.completed, userId: value);
    }
  }
}
