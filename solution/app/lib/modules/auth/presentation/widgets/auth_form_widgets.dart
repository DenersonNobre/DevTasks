import 'package:flutter/material.dart';

import 'package:devtasks_app/global/theme/tokens.dart';

/// Largura máxima do formulário de autenticação (evita linha longa no desktop).
const double authFormMaxWidth = 420;

/// Mensagem de erro de formulário (uma por tela; key explícita para o teste).
class AuthFormMessage extends StatelessWidget {
  const AuthFormMessage({super.key, required this.message, required this.errorKey});

  final String? message;
  final Key errorKey;

  @override
  Widget build(BuildContext context) {
    final text = message;
    if (text == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space4),
      child: Text(
        text,
        key: errorKey,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

/// Campo de texto do formulário de autenticação (senha obscura por padrão).
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
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

/// Botão de submissão com estado de carregamento (desabilita e mostra indicador).
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.isLoading,
    required this.label,
    required this.submitKey,
    required this.onSubmit,
  });

  static const double _spinnerSize = 20;
  static const double _spinnerStroke = 2;

  final bool isLoading;
  final String label;
  final Key submitKey;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => FilledButton(
        key: submitKey,
        onPressed: isLoading ? null : onSubmit,
        child: isLoading
            ? const SizedBox.square(
                dimension: _spinnerSize,
                child: CircularProgressIndicator(strokeWidth: _spinnerStroke),
              )
            : Text(label),
      );
}
