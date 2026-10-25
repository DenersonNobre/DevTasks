// solution/app/lib/modules/workspace/presentation/workspace_controller.dart
// Notifier orquestrador de seleção e carregamento de workspaces (D-07).

import 'package:devtasks_app/global/kernel/result.dart';
import 'package:devtasks_app/modules/workspace/domain/workspace_client.dart';
import 'package:devtasks_app/modules/workspace/domain/workspace_item.dart';
import 'package:devtasks_app/modules/workspace/infrastructure/workspace_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'workspace_state.dart';

final workspaceControllerProvider =
    NotifierProvider<WorkspaceController, WorkspaceState>(
  WorkspaceController.new,
);

final class WorkspaceController extends Notifier<WorkspaceState> {
  @override
  WorkspaceState build() => const WorkspaceState();

  IWorkspaceClient get _client => ref.read(workspaceClientProvider);

  Future<void> load({required String token}) async {
    state = state.copyWith(status: WorkspaceStatus.loading, clearMessage: true);

    final result = await _client.listByUser(token: token);
    switch (result) {
      case Failure(:final failure):
        state = state.copyWith(
          status: WorkspaceStatus.error,
          message: failure.message,
        );
      case Success(:final value):
        final currentSelected = state.selectedWorkspace;
        final stillExists = currentSelected != null &&
            value.any((w) => w.id == currentSelected.id);

        final selected = stillExists
            ? currentSelected
            : (value.isNotEmpty ? value.first : null);

        state = state.copyWith(
          status: WorkspaceStatus.ready,
          workspaces: value,
          selectedWorkspace: selected,
          clearSelectedWorkspace: selected == null,
          clearMessage: true,
        );
    }
  }

  void selectWorkspace(WorkspaceItem item) {
    state = state.copyWith(selectedWorkspace: item, clearMessage: true);
  }

  Future<bool> create({
    required String name,
    required String token,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(nameError: 'Informe o nome do workspace.');
      return false;
    }
    if (trimmed.length > 100) {
      state = state.copyWith(
        nameError: 'Nome deve ter no máximo 100 caracteres.',
      );
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearNameError: true,
      clearMessage: true,
    );

    final result = await _client.create(name: trimmed, token: token);
    switch (result) {
      case Failure(:final failure):
        state = state.copyWith(
          isSubmitting: false,
          message: failure.message,
        );
        return false;
      case Success(:final value):
        final updatedList = [...state.workspaces, value];
        state = state.copyWith(
          isSubmitting: false,
          workspaces: updatedList,
          selectedWorkspace: value,
          clearNameError: true,
          clearMessage: true,
        );
        return true;
    }
  }
}

