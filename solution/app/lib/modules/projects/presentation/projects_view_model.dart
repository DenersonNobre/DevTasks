// solution/app/lib/modules/projects/presentation/projects_view_model.dart
// ViewModel de projetos (D-07): intents -> porta injetada -> estado imutável.
// Puro: sem BuildContext, sem I/O próprio (porta via Riverpod).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:devtasks_app/global/kernel/.kernel.dart';
import 'package:devtasks_app/modules/projects/domain/.domain.dart';
import 'package:devtasks_app/modules/projects/infrastructure/.infrastructure.dart';

import 'projects_state.dart';

/// Provider do ViewModel da tela de projetos.
final projectsViewModelProvider =
    NotifierProvider<ProjectsViewModel, ProjectsState>(ProjectsViewModel.new);

/// Orquestra listagem, criação e renomeação de projetos do workspace.
final class ProjectsViewModel extends Notifier<ProjectsState> {
  @override
  ProjectsState build() => const ProjectsState();

  /// Intent: carregar os projetos ativos do workspace (INV-01 no servidor).
  Future<void> load({required String workspaceId, required String token}) async {
    state = state.copyWith(status: ProjectsStatus.loading, clearMessage: true);

    final result = await ref.read(projectClientProvider).listByWorkspace(
          workspaceId: workspaceId,
          token: token,
        );
    switch (result) {
      case Failure(:final failure):
        state = state.copyWith(status: ProjectsStatus.error, message: failure.message);
        return;
      case Success(:final value):
        state = state.copyWith(
          status: ProjectsStatus.ready,
          projects: value,
          clearMessage: true,
        );
    }
  }

  /// Intent: criar projeto (INV-06 é aplicado no servidor; erro sobe tipado).
  Future<void> create({
    required String workspaceId,
    required String name,
    required String token,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(nameError: 'Informe o nome do projeto.');
      return;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearNameError: true,
      clearMessage: true,
    );

    final result = await ref.read(projectClientProvider).create(
          workspaceId: workspaceId,
          name: trimmed,
          token: token,
        );
    switch (result) {
      case Failure(:final failure):
        state = state.copyWith(
          isSubmitting: false,
          message: failure.message,
          nameError: _fieldErrorOf(failure),
        );
        return;
      case Success(:final value):
        state = state.copyWith(
          isSubmitting: false,
          projects: [...state.projects, value],
          clearMessage: true,
        );
    }
  }

  /// Intent: renomear um projeto existente.
  Future<void> rename({
    required String projectId,
    required String name,
    required String token,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(nameError: 'Informe o nome do projeto.');
      return;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearNameError: true,
      clearMessage: true,
    );

    final result = await ref.read(projectClientProvider).rename(
          projectId: projectId,
          name: trimmed,
          token: token,
        );
    switch (result) {
      case Failure(:final failure):
        state = state.copyWith(
          isSubmitting: false,
          message: failure.message,
          nameError: _fieldErrorOf(failure),
        );
        return;
      case Success(:final value):
        state = state.copyWith(
          isSubmitting: false,
          projects: _replace(state.projects, value),
          clearMessage: true,
        );
    }
  }

  /// Intent: arquivar um projeto (INV-05 / RF-08).
  ///
  /// Ao arquivar com sucesso, o projeto é removido da lista ativa (RF-08).
  Future<void> archive({
    required String projectId,
    required String token,
  }) async {
    state = state.copyWith(isSubmitting: true, clearMessage: true);

    final result = await ref.read(projectClientProvider).archive(
          projectId: projectId,
          token: token,
        );

    switch (result) {
      case Failure(:final failure):
        state = state.copyWith(
          isSubmitting: false,
          message: failure.message,
        );
        return;
      case Success():
        state = state.copyWith(
          isSubmitting: false,
          projects: state.projects.where((p) => p.id != projectId).toList(),
          clearMessage: true,
        );
    }
  }

  String? _fieldErrorOf(IFailure failure) =>
      failure is ValidationFailure ? failure.message : null;

  List<ProjectSummary> _replace(
    List<ProjectSummary> current,
    ProjectSummary updated,
  ) =>
      current
          .map((project) => project.id == updated.id ? updated : project)
          .toList();
}
