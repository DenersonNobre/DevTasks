import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:devtasks_app/global/router/app_routes.dart';
import 'package:devtasks_app/global/theme/tokens.dart';
import 'package:devtasks_app/modules/auth/presentation/login/login_view_model.dart';
import 'package:devtasks_app/modules/auth/presentation/widgets/auth_form_widgets.dart';

/// Tela de login (D-07): renderiza o estado do ViewModel e despacha intents.
/// Não valida nem chama rede — apenas apresenta e delega.
class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginViewModelProvider);
    ref.listen(
      loginViewModelProvider.select((value) => value.isCompleted),
      (_, completed) => _onCompleted(context, completed),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Entrar')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space6),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: authFormMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTextField(
                  fieldKey: const Key('login-email'),
                  controller: _email,
                  label: 'E-mail',
                  errorText: state.emailError,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: AppSpacing.space4),
                AuthTextField(
                  fieldKey: const Key('login-password'),
                  controller: _password,
                  label: 'Senha',
                  errorText: state.passwordError,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                ),
                AuthFormMessage(
                  message: state.message,
                  errorKey: const Key('login-form-error'),
                ),
                const SizedBox(height: AppSpacing.space6),
                AuthSubmitButton(
                  isLoading: state.isLoading,
                  label: 'Entrar',
                  submitKey: const Key('login-submit'),
                  onSubmit: _submit,
                ),
                TextButton(
                  key: const Key('login-go-register'),
                  onPressed: state.isLoading ? null : _goToRegister,
                  child: const Text('Criar conta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() => ref.read(loginViewModelProvider.notifier).submit(
        rawEmail: _email.text,
        rawPassword: _password.text,
      );

  void _goToRegister() => Navigator.pushReplacementNamed(context, AppRoutes.register);

  void _onCompleted(BuildContext context, bool completed) {
    if (!completed || !context.mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.privateArea);
  }
}
