// solution/app/lib/modules/tasks/presentation/tasks_view.dart
// Tela e controle de CRUD de Tarefas (UC-04.01 / RF-09).
// MVVM puro com Riverpod (D-07).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/task_item.dart';
import '../domain/task_priority.dart';
import 'tasks_state.dart';
import 'tasks_view_model.dart';
import 'widgets/priority_badge.dart';

/// Tela de tarefas do projeto com suporte a criação, listagem, edição e exclusão.
class TasksView extends ConsumerStatefulWidget {
  const TasksView({
    super.key,
    required this.projectId,
    this.projectName,
    required this.token,
  });

  final String projectId;
  final String? projectName;
  final String token;

  @override
  ConsumerState<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends ConsumerState<TasksView> {
  final _titleController = TextEditingController();
  var _selectedPriority = TaskPriority.medium;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await ref.read(tasksViewModelProvider.notifier).load(
          projectId: widget.projectId,
          token: widget.token,
        );
  }

  Future<void> _create() async {
    await ref.read(tasksViewModelProvider.notifier).create(
          projectId: widget.projectId,
          title: _titleController.text,
          priority: _selectedPriority,
          token: widget.token,
        );

    final titleError = ref.read(tasksViewModelProvider).titleError;
    if (titleError == null) {
      _titleController.clear();
      setState(() => _selectedPriority = TaskPriority.medium);
    }
  }

  Future<void> _edit(TaskItem task) {
    return showDialog<void>(
      context: context,
      builder: (context) => _EditTaskDialog(
        task: task,
        onSave: (newTitle, newPriority) =>
            ref.read(tasksViewModelProvider.notifier).update(
                  taskId: task.id,
                  title: newTitle,
                  priority: newPriority,
                  token: widget.token,
                ),
      ),
    );
  }

  Future<void> _delete(TaskItem task) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('task-delete-dialog'),
        title: const Text('Excluir tarefa'),
        content: Text('Deseja excluir a tarefa "${task.title}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('task-delete-confirm-button'),
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(tasksViewModelProvider.notifier).delete(
                    taskId: task.id,
                    token: widget.token,
                  );
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tasksViewModelProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.projectName != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              widget.projectName!,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        _CreateTaskForm(
          controller: _titleController,
          selectedPriority: _selectedPriority,
          onPriorityChanged: (p) => setState(() => _selectedPriority = p),
          state: state,
          onCreate: _create,
        ),
        const Divider(height: 16),
        Expanded(
          child: _TaskList(
            state: state,
            onRetry: _load,
            onEdit: _edit,
            onDelete: _delete,
          ),
        ),
      ],
    );
  }
}

class _CreateTaskForm extends StatelessWidget {
  const _CreateTaskForm({
    required this.controller,
    required this.selectedPriority,
    required this.onPriorityChanged,
    required this.state,
    required this.onCreate,
  });

  final TextEditingController controller;
  final TaskPriority selectedPriority;
  final ValueChanged<TaskPriority> onPriorityChanged;
  final TasksState state;
  final Future<void> Function() onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('task-title-field'),
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Título da tarefa',
                    errorText: state.titleError,
                    border: const OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onCreate(),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<TaskPriority>(
                key: const Key('task-priority-selector'),
                value: selectedPriority,
                onChanged: (p) => p != null ? onPriorityChanged(p) : null,
                items: TaskPriority.values.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text(p.label),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(
                key: const Key('task-create-button'),
                onPressed: state.isSubmitting ? null : onCreate,
                child: Text(state.isSubmitting ? 'Salvando...' : 'Adicionar tarefa'),
              ),
              const SizedBox(width: 12),
              if (state.message != null && state.status != TasksStatus.error)
                Expanded(
                  child: Text(
                    state.message!,
                    key: const Key('task-error-message'),
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

class _TaskList extends StatelessWidget {
  const _TaskList({
    required this.state,
    required this.onRetry,
    required this.onEdit,
    required this.onDelete,
  });

  final TasksState state;
  final Future<void> Function() onRetry;
  final void Function(TaskItem task) onEdit;
  final void Function(TaskItem task) onDelete;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(key: Key('tasks-loading')),
      );
    }

    if (state.status == TasksStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.message ?? 'Falha ao carregar tarefas.'),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('tasks-retry-button'),
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
          'Nenhuma tarefa ainda.',
          key: Key('tasks-empty-state'),
        ),
      );
    }

    return ListView.builder(
      key: const Key('tasks-list'),
      itemCount: state.tasks.length,
      itemBuilder: (context, index) {
        final task = state.tasks[index];
        return ListTile(
          key: Key('task-item-${task.id}'),
          leading: PriorityBadge(priority: task.priority),
          title: Text(task.title),
          subtitle: task.description != null ? Text(task.description!) : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: Key('task-edit-button-${task.id}'),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar',
                onPressed: () => onEdit(task),
              ),
              IconButton(
                key: Key('task-delete-button-${task.id}'),
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Excluir',
                onPressed: () => onDelete(task),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EditTaskDialog extends StatefulWidget {
  const _EditTaskDialog({
    required this.task,
    required this.onSave,
  });

  final TaskItem task;
  final Future<void> Function(String newTitle, TaskPriority newPriority) onSave;

  @override
  State<_EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<_EditTaskDialog> {
  late final TextEditingController _controller;
  late TaskPriority _priority;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.task.title);
    _priority = widget.task.priority;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSubmitting = true);
    await widget.onSave(title, _priority);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('task-edit-dialog'),
      title: const Text('Editar tarefa'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('task-edit-title-field'),
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Título da tarefa',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TaskPriority>(
            initialValue: _priority,
            decoration: const InputDecoration(
              labelText: 'Prioridade',
              border: OutlineInputBorder(),
            ),
            onChanged: (p) => p != null ? setState(() => _priority = p) : null,
            items: TaskPriority.values.map((p) {
              return DropdownMenuItem(
                value: p,
                child: Text(p.label),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('task-edit-save-button'),
          onPressed: _isSubmitting ? null : _submit,
          child: Text(_isSubmitting ? 'Salvando...' : 'Salvar'),
        ),
      ],
    );
  }
}
