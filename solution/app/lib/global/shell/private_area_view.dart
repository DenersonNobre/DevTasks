import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:devtasks_app/global/router/app_routes.dart';
import 'package:devtasks_app/global/session/.session.dart';

/// Placeholder da área privada até a EPIC-02 (workspaces/projetos).
/// Existe para provar navegação pós-login e logout de ponta a ponta.
class PrivateAreaView extends ConsumerWidget {
  const PrivateAreaView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
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
        body: const Center(child: Text('Área privada (EPIC-02)')),
      );

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(sessionControllerProvider).signOut();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }
}
