import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:devtasks_app/global/router/app_routes.dart';
import 'package:devtasks_app/modules/auth/.presentation.dart';
import 'package:devtasks_app/modules/auth/presentation/register/register_view_model.dart';

/// Tela de cadastro (D-07): renderiza o estado do ViewModel e despacha intents.
/// Não valida nem chama rede — apenas apresenta e delega.
class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerViewModelProvider);
    ref.listen(
      registerViewModelProvider.select((value) => value.isCompleted),
      (_, completed) => _onCompleted(context, completed),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('register-name'),
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  decoration: InputDecoration(labelText: 'Nome', errorText: state.nameError),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('register-email'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(labelText: 'E-mail', errorText: state.emailError),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('register-password'),
                  controller: _password,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(labelText: 'Senha', errorText: state.passwordError),
                ),
                _FormMessage(message: state.message),
                const SizedBox(height: 24),
                _SubmitButton(state: state, onSubmit: _submit),
                TextButton(
                  key: const Key('register-go-login'),
                  onPressed: state.isLoading ? null : _goToLogin,
                  child: const Text('Já tenho conta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() => ref.read(registerViewModelProvider.notifier).submit(
        rawName: _name.text,
        rawEmail: _email.text,
        rawPassword: _password.text,
      );

  void _goToLogin() => Navigator.pushReplacementNamed(context, AppRoutes.login);

  void _onCompleted(BuildContext context, bool completed) {
    if (!completed || !context.mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }
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
        key: const Key('register-form-error'),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

final class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.state, required this.onSubmit});

  final RegisterState state;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => FilledButton(
        key: const Key('register-submit'),
        onPressed: state.isLoading ? null : onSubmit,
        child: state.isLoading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Criar conta'),
      );
}
