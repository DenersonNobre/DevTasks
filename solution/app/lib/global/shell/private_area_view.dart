import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:devtasks_app/global/router/app_routes.dart';
import 'package:devtasks_app/global/session/.session.dart';
import 'package:devtasks_app/modules/auth/infrastructure/auth_client_provider.dart';

/// Área privada autenticada de referência (F1.8).
///
/// Exibe metadados derivados da sessão ativa e realiza logout ponta a ponta
/// (notifica o servidor e limpa a sessão local de forma segura e resiliente).
class PrivateAreaView extends ConsumerWidget {
  const PrivateAreaView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionControllerProvider).state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projetos'),
        actions: [
          TextButton(
            key: const Key('private-logout'),
            onPressed: () => _signOut(context, ref),
            child: const Text('Sair'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Área privada (EPIC-02)'),
            const SizedBox(height: 12),
            Text(
              sessionState.isAuthenticated
                  ? 'Sessão ativa'
                  : 'Sessão não identificada',
              key: const Key('session-status-text'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final sessionController = ref.read(sessionControllerProvider);
    final authClient = ref.read(authClientProvider);
    final token = sessionController.state.token;

    // Tentativa resiliente de revogação remota no servidor
    if (token != null && token.isNotEmpty) {
      try {
        await authClient.signOut(token);
      } catch (_) {
        // Falha de rede não impede limpeza local (fail-safe)
      }
    }

    // Limpeza da sessão local (SEMPRE executada)
    await sessionController.signOut();

    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }
}
