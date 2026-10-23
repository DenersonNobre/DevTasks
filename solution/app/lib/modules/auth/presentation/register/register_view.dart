import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:devtasks_app/global/router/app_routes.dart';
import 'package:devtasks_app/global/theme/tokens.dart';
import 'package:devtasks_app/modules/auth/presentation/register/register_view_model.dart';
import 'package:devtasks_app/modules/auth/presentation/widgets/auth_form_widgets.dart';

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
          padding: const EdgeInsets.all(AppSpacing.space6),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: authFormMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AuthTextField(
                  fieldKey: const Key('register-name'),
                  controller: _name,
                  label: 'Nome',
                  errorText: state.nameError,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                ),
                const SizedBox(height: AppSpacing.space4),
                _AuthTextField(
                  fieldKey: const Key('register-email'),
                  controller: _email,
                  label: 'E-mail',
                  errorText: state.emailError,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: AppSpacing.space4),
                _AuthTextField(
                  fieldKey: const Key('register-password'),
                  controller: _password,
                  label: 'Senha',
                  errorText: state.passwordError,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                ),
                AuthFormMessage(
                  message: state.message,
                  errorKey: const Key('register-form-error'),
                ),
                const SizedBox(height: AppSpacing.space6),
                AuthSubmitButton(
                  isLoading: state.isLoading,
                  label: 'Criar conta',
                  submitKey: const Key('register-submit'),
                  onSubmit: _submit,
                ),
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

/// Campo de texto do cadastro, sobre o tema de `F1.5`.
class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) => TextField(
        key: fieldKey,
        controller: controller,
        obscureText: obscureText,
        autocorrect: !obscureText,
        enableSuggestions: !obscureText,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        autofillHints: autofillHints,
        decoration: InputDecoration(labelText: label, errorText: errorText),
      );
}
