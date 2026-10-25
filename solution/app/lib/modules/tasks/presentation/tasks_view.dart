// solution/app/lib/modules/tasks/presentation/tasks_view.dart
// Tela e controle de CRUD de Tarefas, Quadro Kanban e Atribuição de Responsável
// (UC-04.01 / UC-04.02 / UC-04.03 / RF-09 / RF-10 / RF-11 / INV-03 / INV-04).
// MVVM puro com Riverpod (D-07).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:devtasks_app/modules/comments/presentation/comments_sheet.dart';
import '../domain/task_item.dart';
import '../domain/task_priority.dart';
import '../domain/task_status.dart';
import 'tasks_state.dart';
import 'tasks_view_model.dart';
import 'widgets/priority_badge.dart';

/// Modo de visualização de tarefas.
enum TasksViewMode {
  list,
  kanban,
}

/// Tela de tarefas do projeto com suporte a lista, quadro Kanban de 3 colunas (D-01)
/// e atribuição de responsável (INV-03 / RF-11).
class TasksView extends ConsumerStatefulWidget {
  const TasksView({
    super.key,
    required this.projectId,
    this.projectName,
    required this.token,
    this.initialMode = TasksViewMode.list,
  });

  final String projectId;
  final String? projectName;
  final String token;
  final TasksViewMode initialMode;

  @override
  ConsumerState<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends ConsumerState<TasksView> {
  final _titleController = TextEditingController();
  var _selectedPriority = TaskPriority.medium;
  late TasksViewMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
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

  Future<void> _move(TaskItem task) {
    return showDialog<void>(
      context: context,
      builder: (context) => _MoveTaskDialog(
        task: task,
        onMove: (targetStatus) =>
            ref.read(tasksViewModelProvider.notifier).move(
                  taskId: task.id,
                  targetStatus: targetStatus,
                  expectedUpdatedAt: task.updatedAt ?? DateTime.now().toUtc(),
                  token: widget.token,
                ),
      ),
    );
  }

  Future<void> _assign(TaskItem task) {
    return showDialog<void>(
      context: context,
      builder: (context) => _AssignTaskDialog(
        task: task,
        onSave: (userId) =>
            ref.read(tasksViewModelProvider.notifier).assign(
                  taskId: task.id,
                  assignedUserId: userId,
                  token: widget.token,
                ),
      ),
    );
  }

  void _onDrop(TaskItem task, TaskStatus targetStatus) {
    if (task.status == targetStatus) return;
    ref.read(tasksViewModelProvider.notifier).move(
          taskId: task.id,
          targetStatus: targetStatus,
          expectedUpdatedAt: task.updatedAt ?? DateTime.now().toUtc(),
          token: widget.token,
        );
  }

  void _openComments(TaskItem task) {
    CommentsSheet.show(context, task: task, token: widget.token);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tasksViewModelProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              if (widget.projectName != null)
                Expanded(
                  child: Text(
                    widget.projectName!,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                )
              else
                const Spacer(),
              SegmentedButton<TasksViewMode>(
                key: const Key('tasks-mode-toggle'),
                segments: const [
                  ButtonSegment(
                    value: TasksViewMode.list,
                    icon: Icon(Icons.list),
                    label: Text('Lista'),
                  ),
                  ButtonSegment(
                    value: TasksViewMode.kanban,
                    icon: Icon(Icons.view_column),
                    label: Text('Kanban'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (modes) {
                  if (modes.isNotEmpty) {
                    setState(() => _mode = modes.first);
                  }
                },
              ),
            ],
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
          child: _mode == TasksViewMode.kanban
              ? _KanbanBoard(
                  state: state,
                  onRetry: _load,
                  onMove: _move,
                  onAssign: _assign,
                  onComments: _openComments,
                  onEdit: _edit,
                  onDelete: _delete,
                  onDrop: _onDrop,
                )
              : _TaskList(
                  state: state,
                  onRetry: _load,
                  onAssign: _assign,
                  onComments: _openComments,
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
    required this.onAssign,
    required this.onComments,
    required this.onEdit,
    required this.onDelete,
  });

  final TasksState state;
  final Future<void> Function() onRetry;
  final void Function(TaskItem task) onAssign;
  final void Function(TaskItem task) onComments;
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
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description != null) Text(task.description!),
              if (task.assignedUserId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        key: Key('task-assignee-avatar-${task.id}'),
                        radius: 8,
                        child: const Icon(Icons.person, size: 10),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Resp: ${task.assignedUserId}',
                        key: Key('task-assignee-label-${task.id}'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: Key('task-comments-button-${task.id}'),
                icon: const Icon(Icons.comment_outlined),
                tooltip: 'Comentários',
                onPressed: () => onComments(task),
              ),
              IconButton(
                key: Key('task-assign-button-${task.id}'),
                icon: const Icon(Icons.person_add_alt_1_outlined),
                tooltip: 'Atribuir',
                onPressed: () => onAssign(task),
              ),
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

class _KanbanBoard extends StatelessWidget {
  const _KanbanBoard({
    required this.state,
    required this.onRetry,
    required this.onMove,
    required this.onAssign,
    required this.onComments,
    required this.onEdit,
    required this.onDelete,
    required this.onDrop,
  });

  final TasksState state;
  final Future<void> Function() onRetry;
  final void Function(TaskItem task) onMove;
  final void Function(TaskItem task) onAssign;
  final void Function(TaskItem task) onComments;
  final void Function(TaskItem task) onEdit;
  final void Function(TaskItem task) onDelete;
  final void Function(TaskItem task, TaskStatus targetStatus) onDrop;

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

    // 3 colunas fechadas do Kanban (D-01 / INV-04).
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final status in TaskStatus.values)
          Expanded(
            child: _KanbanColumn(
              status: status,
              tasks: state.tasks.where((t) => t.status == status).toList(),
              onMove: onMove,
              onAssign: onAssign,
              onComments: onComments,
              onEdit: onEdit,
              onDelete: onDelete,
              onDrop: onDrop,
            ),
          ),
      ],
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.status,
    required this.tasks,
    required this.onMove,
    required this.onAssign,
    required this.onComments,
    required this.onEdit,
    required this.onDelete,
    required this.onDrop,
  });

  final TaskStatus status;
  final List<TaskItem> tasks;
  final void Function(TaskItem task) onMove;
  final void Function(TaskItem task) onAssign;
  final void Function(TaskItem task) onComments;
  final void Function(TaskItem task) onEdit;
  final void Function(TaskItem task) onDelete;
  final void Function(TaskItem task, TaskStatus targetStatus) onDrop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DragTarget<TaskItem>(
      onAcceptWithDetails: (details) => onDrop(details.data, status),
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Container(
          key: Key('kanban-column-${status.value}'),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: isHovered
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isHovered
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Text(
                  '${status.label} (${tasks.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Text(
                          'Sem tarefas',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return _KanbanCard(
                            task: task,
                            onMove: onMove,
                            onAssign: onAssign,
                            onComments: onComments,
                            onEdit: onEdit,
                            onDelete: onDelete,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KanbanCard extends StatelessWidget {
  const _KanbanCard({
    required this.task,
    required this.onMove,
    required this.onAssign,
    required this.onComments,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskItem task;
  final void Function(TaskItem task) onMove;
  final void Function(TaskItem task) onAssign;
  final void Function(TaskItem task) onComments;
  final void Function(TaskItem task) onEdit;
  final void Function(TaskItem task) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cardContent = Card(
      key: Key('kanban-card-${task.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PriorityBadge(priority: task.priority),
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: Key('task-comments-button-${task.id}'),
                          icon: const Icon(Icons.comment_outlined, size: 18),
                          tooltip: 'Comentários',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: () => onComments(task),
                        ),
                        IconButton(
                          key: Key('task-assign-button-${task.id}'),
                          icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                          tooltip: 'Atribuir responsável',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: () => onAssign(task),
                        ),
                        IconButton(
                          key: Key('task-move-button-${task.id}'),
                          icon: const Icon(Icons.swap_horiz, size: 18),
                          tooltip: 'Mover tarefa',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: () => onMove(task),
                        ),
                        IconButton(
                          key: Key('task-edit-button-${task.id}'),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Editar',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: () => onEdit(task),
                        ),
                        IconButton(
                          key: Key('task-delete-button-${task.id}'),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          tooltip: 'Excluir',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: () => onDelete(task),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (task.assignedUserId != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    key: Key('task-assignee-avatar-${task.id}'),
                    radius: 10,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      size: 12,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Resp: ${task.assignedUserId}',
                      key: Key('task-assignee-label-${task.id}'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    return Draggable<TaskItem>(
      data: task,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: cardContent,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: cardContent,
      ),
      child: cardContent,
    );
  }
}

class _AssignTaskDialog extends StatefulWidget {
  const _AssignTaskDialog({
    required this.task,
    required this.onSave,
  });

  final TaskItem task;
  final Future<void> Function(String? assignedUserId) onSave;

  @override
  State<_AssignTaskDialog> createState() => _AssignTaskDialogState();
}

class _AssignTaskDialogState extends State<_AssignTaskDialog> {
  late final TextEditingController _controller;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.task.assignedUserId ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit(String? userId) async {
    setState(() => _isSubmitting = true);
    await widget.onSave(userId);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final hasAssignee = widget.task.assignedUserId != null;

    return AlertDialog(
      key: const Key('task-assign-dialog'),
      title: const Text('Atribuir responsável'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informe o identificador do membro do workspace (INV-03):'),
          const SizedBox(height: 12),
          TextField(
            key: const Key('task-assign-user-field'),
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'ID do usuário',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (v) => _submit(v.trim().isEmpty ? null : v.trim()),
          ),
        ],
      ),
      actions: [
        if (hasAssignee)
          TextButton(
            key: const Key('task-unassign-button'),
            onPressed: _isSubmitting ? null : () => _submit(null),
            child: const Text('Desatribuir'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('task-assign-save-button'),
          onPressed: _isSubmitting
              ? null
              : () {
                  final text = _controller.text.trim();
                  _submit(text.isEmpty ? null : text);
                },
          child: Text(_isSubmitting ? 'Salvando...' : 'Salvar'),
        ),
      ],
    );
  }
}

class _MoveTaskDialog extends StatelessWidget {
  const _MoveTaskDialog({
    required this.task,
    required this.onMove,
  });

  final TaskItem task;
  final void Function(TaskStatus targetStatus) onMove;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('task-move-dialog'),
      title: const Text('Mover tarefa'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Mover "${task.title}" para qual coluna?'),
          const SizedBox(height: 16),
          for (final status in TaskStatus.values)
            if (status != task.status)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  key: Key('task-move-to-${status.value}'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onMove(status);
                  },
                  child: Text('Mover para ${status.label}'),
                ),
              ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
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
