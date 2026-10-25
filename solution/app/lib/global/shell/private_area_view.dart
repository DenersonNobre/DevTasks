// solution/app/lib/global/shell/private_area_view.dart
// Shell da área privada do app (D-07 / R1 da auditoria).
// Conecta seleção de Workspace -> Lista de Projetos -> Tarefas/Kanban -> Comentários.

import 'package:devtasks_app/global/router/app_routes.dart';
import 'package:devtasks_app/global/session/.session.dart';
import 'package:devtasks_app/modules/auth/infrastructure/auth_client_provider.dart';
import 'package:devtasks_app/modules/projects/presentation/projects_view.dart';
import 'package:devtasks_app/modules/tasks/presentation/tasks_view.dart';
import 'package:devtasks_app/modules/workspace/domain/workspace_item.dart';
import 'package:devtasks_app/modules/workspace/presentation/workspace_controller.dart';
import 'package:devtasks_app/modules/workspace/presentation/workspace_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PrivateAreaView extends ConsumerStatefulWidget {
  const PrivateAreaView({super.key});

  @override
  ConsumerState<PrivateAreaView> createState() => _PrivateAreaViewState();
}

class _PrivateAreaViewState extends ConsumerState<PrivateAreaView> {
  final _newWsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWorkspaces();
    });
  }

  @override
  void dispose() {
    _newWsController.dispose();
    super.dispose();
  }

  void _loadWorkspaces() {
    final session = ref.read(sessionControllerProvider).state;
    if (session.isAuthenticated && session.token != null) {
      ref.read(workspaceControllerProvider.notifier).load(token: session.token!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionControllerProvider).state;
    final wsState = ref.watch(workspaceControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(wsState),
        actions: [
          TextButton(
            key: const Key('private-logout'),
            onPressed: () => _signOut(context, ref),
            child: const Text('Sair'),
          ),
        ],
      ),
      body: _buildBody(context, sessionState, wsState),
    );
  }

  Widget _buildAppBarTitle(WorkspaceState wsState) {
    if (wsState.selectedWorkspace == null) {
      return const Text('Projetos');
    }

    return PopupMenuButton<WorkspaceItem>(
      key: const Key('workspace-selector'),
      tooltip: 'Selecionar workspace',
      onSelected: (ws) {
        ref.read(workspaceControllerProvider.notifier).selectWorkspace(ws);
      },
      itemBuilder: (context) => [
        for (final ws in wsState.workspaces)
          PopupMenuItem<WorkspaceItem>(
            value: ws,
            child: Row(
              children: [
                if (ws.id == wsState.selectedWorkspace?.id)
                  const Icon(Icons.check, size: 16)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(ws.name)),
              ],
            ),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              wsState.selectedWorkspace!.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SessionState sessionState,
    WorkspaceState wsState,
  ) {
    if (wsState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(key: Key('workspaces-loading')),
      );
    }

    if (wsState.status == WorkspaceStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(wsState.message ?? 'Falha ao carregar workspaces.'),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('workspaces-retry-button'),
              onPressed: _loadWorkspaces,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (wsState.workspaces.isEmpty) {
      return _buildFirstWorkspaceForm(context, sessionState, wsState);
    }

    if (wsState.selectedWorkspace == null) {
      return const Center(
        child: Text('Nenhum workspace selecionado.'),
      );
    }

    final token = sessionState.token ?? '';
    final currentWs = wsState.selectedWorkspace!;

    return ProjectsView(
      key: ValueKey('projects-view-${currentWs.id}'),
      workspaceId: currentWs.id,
      token: token,
      onSelectProject: (project) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(title: Text(project.name)),
              body: TasksView(
                projectId: project.id,
                projectName: project.name,
                token: token,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFirstWorkspaceForm(
    BuildContext context,
    SessionState sessionState,
    WorkspaceState wsState,
  ) {
    return Center(
      child: Card(
        key: const Key('first-workspace-form'),
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bem-vindo ao DevTasks!',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Para começar, crie seu primeiro workspace:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('first-workspace-name-field'),
                controller: _newWsController,
                decoration: InputDecoration(
                  labelText: 'Nome do workspace',
                  border: const OutlineInputBorder(),
                  errorText: wsState.nameError,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('first-workspace-create-button'),
                onPressed: wsState.isSubmitting
                    ? null
                    : () async {
                        final token = sessionState.token;
                        if (token == null) return;
                        final ok = await ref
                            .read(workspaceControllerProvider.notifier)
                            .create(name: _newWsController.text, token: token);
                        if (ok) {
                          _newWsController.clear();
                        }
                      },
                child: Text(
                  wsState.isSubmitting ? 'Criando...' : 'Criar Workspace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final sessionController = ref.read(sessionControllerProvider);
    final authClient = ref.read(authClientProvider);
    final token = sessionController.state.token;

    if (token != null && token.isNotEmpty) {
      try {
        await authClient.signOut(token);
      } catch (_) {}
    }

    await sessionController.signOut();

    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }
}
