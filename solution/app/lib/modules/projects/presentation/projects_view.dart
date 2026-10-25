// solution/app/lib/modules/projects/presentation/projects_view.dart
// View de projetos (D-07): renderiza estado e despacha intents. Sem regra de negócio.
// Não abre sessão própria: recebe `workspaceId` e `token` da camada que a hospeda.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/project_summary.dart';
import 'projects_state.dart';
import 'projects_view_model.dart';

/// Lista + formulário de projetos de um workspace.
class ProjectsView extends ConsumerStatefulWidget {
  const ProjectsView({
    super.key,
    required this.workspaceId,
    required this.token,
  });

  final String workspaceId;
  final String token;

  @override
  ConsumerState<ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends ConsumerState<ProjectsView> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() => ref.read(projectsViewModelProvider.notifier).load(
        workspaceId: widget.workspaceId,
        token: widget.token,
      );

  Future<void> _create() async {
    await ref.read(projectsViewModelProvider.notifier).create(
          workspaceId: widget.workspaceId,
          name: _nameController.text,
          token: widget.token,
        );
    if (ref.read(projectsViewModelProvider).nameError == null) {
      _nameController.clear();
    }
  }

  Future<void> _rename(ProjectSummary project) {
    return showDialog<void>(
      context: context,
      builder: (context) => _RenameProjectDialog(
        initialName: project.name,
        onSave: (newName) => ref.read(projectsViewModelProvider.notifier).rename(
              projectId: project.id,
              name: newName,
              token: widget.token,
            ),
      ),
    );
  }

  Future<void> _archive(ProjectSummary project) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('project-archive-dialog'),
        title: const Text('Arquivar projeto'),
        content: Text(
          'Deseja arquivar o projeto "${project.name}"? '
          'Ele sairá da lista ativa e se tornará somente-leitura.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('project-archive-confirm-button'),
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(projectsViewModelProvider.notifier).archive(
                    projectId: project.id,
                    token: widget.token,
                  );
            },
            child: const Text('Arquivar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectsViewModelProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CreateForm(
          controller: _nameController,
          state: state,
          onCreate: _create,
        ),
        const Divider(height: 32),
        Expanded(
          child: _ProjectList(
            state: state,
            onRetry: _load,
            onRename: _rename,
            onArchive: _archive,
          ),
        ),
      ],
    );
  }
}

class _CreateForm extends StatelessWidget {
  const _CreateForm({
    required this.controller,
    required this.state,
    required this.onCreate,
  });

  final TextEditingController controller;
  final ProjectsState state;
  final Future<void> Function() onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const Key('project-name-field'),
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Nome do projeto',
              errorText: state.nameError,
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onCreate(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton(
                key: const Key('project-create-button'),
                onPressed: state.isSubmitting ? null : onCreate,
                child: Text(state.isSubmitting ? 'Salvando...' : 'Criar projeto'),
              ),
              const SizedBox(width: 12),
              if (state.message != null && state.status != ProjectsStatus.error)
                Expanded(
                  child: Text(
                    state.message!,
                    key: const Key('project-error-message'),
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectList extends StatelessWidget {
  const _ProjectList({
    required this.state,
    required this.onRetry,
    required this.onRename,
    required this.onArchive,
  });

  final ProjectsState state;
  final Future<void> Function() onRetry;
  final void Function(ProjectSummary project) onRename;
  final void Function(ProjectSummary project) onArchive;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(key: Key('projects-loading')),
      );
    }

    if (state.status == ProjectsStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.message ?? 'Falha ao carregar projetos.'),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('projects-retry-button'),
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (state.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum projeto ainda.',
          key: Key('projects-empty-state'),
        ),
      );
    }

    return ListView.builder(
      key: const Key('projects-list'),
      itemCount: state.projects.length,
      itemBuilder: (context, index) {
        final project = state.projects[index];
        return ListTile(
          key: Key('project-item-${project.id}'),
          leading: const Icon(Icons.folder_outlined),
          title: Text(project.name),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: Key('project-rename-button-${project.id}'),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Renomear',
                onPressed: () => onRename(project),
              ),
              IconButton(
                key: Key('project-archive-button-${project.id}'),
                icon: const Icon(Icons.archive_outlined),
                tooltip: 'Arquivar',
                onPressed: () => onArchive(project),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RenameProjectDialog extends StatefulWidget {
  const _RenameProjectDialog({
    required this.initialName,
    required this.onSave,
  });

  final String initialName;
  final Future<void> Function(String newName) onSave;

  @override
  State<_RenameProjectDialog> createState() => _RenameProjectDialogState();
}

class _RenameProjectDialogState extends State<_RenameProjectDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    await widget.onSave(_controller.text);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('project-rename-dialog'),
      title: const Text('Renomear projeto'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('project-rename-field'),
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Novo nome',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Informe o nome do projeto.' : null,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('project-rename-cancel'),
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('project-rename-submit'),
          onPressed: _isSubmitting ? null : _submit,
          child: Text(_isSubmitting ? 'Salvando...' : 'Salvar'),
        ),
      ],
    );
  }
}
