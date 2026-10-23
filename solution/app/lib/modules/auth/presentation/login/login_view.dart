import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:devtasks_app/global/router/app_routes.dart';
import 'package:devtasks_app/modules/auth/.presentation.dart';
import 'package:devtasks_app/modules/auth/presentation/login/login_view_model.dart';

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
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EmailField(controller: _email, errorText: state.emailError),
                const SizedBox(height: 16),
                _PasswordField(controller: _password, errorText: state.passwordError),
                _FormMessage(message: state.message),
                const SizedBox(height: 24),
                _SubmitButton(state: state, onSubmit: _submit),
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

final class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller, required this.errorText});

  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) => TextField(
        key: const Key('login-email'),
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        decoration: InputDecoration(labelText: 'E-mail', errorText: errorText),
      );
}

final class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.controller, required this.errorText});

  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) => TextField(
        key: const Key('login-password'),
        controller: controller,
        obscureText: true,
        autocorrect: false,
        enableSuggestions: false,
        autofillHints: const [AutofillHints.password],
        decoration: InputDecoration(labelText: 'Senha', errorText: errorText),
      );
}

final class _FormMessage extends StatelessWidget {
  const _FormMessage({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    if (text == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        text,
        key: const Key('login-form-error'),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

final class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.state, required this.onSubmit});

  final LoginState state;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => FilledButton(
        key: const Key('login-submit'),
        onPressed: state.isLoading ? null : onSubmit,
        child: state.isLoading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Entrar'),
      );
}
