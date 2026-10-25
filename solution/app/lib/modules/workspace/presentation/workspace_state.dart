// solution/app/lib/modules/workspace/presentation/workspace_state.dart
// Estado imutável de workspaces do app (D-07).

import 'package:flutter/foundation.dart';

import '../domain/workspace_item.dart';

enum WorkspaceStatus { idle, loading, ready, error }

@immutable
final class WorkspaceState {
  const WorkspaceState({
    this.status = WorkspaceStatus.idle,
    this.workspaces = const [],
    this.selectedWorkspace,
    this.message,
    this.nameError,
    this.isSubmitting = false,
  });

  final WorkspaceStatus status;
  final List<WorkspaceItem> workspaces;
  final WorkspaceItem? selectedWorkspace;
  final String? message;
  final String? nameError;
  final bool isSubmitting;

  bool get isLoading => status == WorkspaceStatus.loading;
  bool get hasWorkspace => selectedWorkspace != null;

  WorkspaceState copyWith({
    WorkspaceStatus? status,
    List<WorkspaceItem>? workspaces,
    WorkspaceItem? selectedWorkspace,
    bool clearSelectedWorkspace = false,
    String? message,
    bool clearMessage = false,
    String? nameError,
    bool clearNameError = false,
    bool? isSubmitting,
  }) =>
      WorkspaceState(
        status: status ?? this.status,
        workspaces: workspaces ?? this.workspaces,
        selectedWorkspace: clearSelectedWorkspace
            ? null
            : (selectedWorkspace ?? this.selectedWorkspace),
        message: clearMessage ? null : (message ?? this.message),
        nameError: clearNameError ? null : (nameError ?? this.nameError),
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );
}

