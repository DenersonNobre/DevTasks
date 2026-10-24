// solution/app/lib/modules/projects/presentation/projects_state.dart
// Estado imutável da tela de projetos (D-07: estado + intents).
// Não carrega token: sessão é estado transversal (global/session/).

import 'package:flutter/foundation.dart';

import '../domain/project_summary.dart';

/// Estágio de carregamento da listagem.
enum ProjectsStatus { idle, loading, ready, error }

/// Retrato imutável da tela de projetos.
@immutable
final class ProjectsState {
  const ProjectsState({
    this.status = ProjectsStatus.idle,
    this.projects = const [],
    this.message,
    this.nameError,
    this.isSubmitting = false,
  });

  final ProjectsStatus status;
  final List<ProjectSummary> projects;
  final String? message;
  final String? nameError;
  final bool isSubmitting;

  bool get isLoading => status == ProjectsStatus.loading;
  bool get isEmpty => status == ProjectsStatus.ready && projects.isEmpty;

  ProjectsState copyWith({
    ProjectsStatus? status,
    List<ProjectSummary>? projects,
    String? message,
    String? nameError,
    bool? isSubmitting,
    bool clearMessage = false,
    bool clearNameError = false,
  }) =>
      ProjectsState(
        status: status ?? this.status,
        projects: projects ?? this.projects,
        message: clearMessage ? null : (message ?? this.message),
        nameError: clearNameError ? null : (nameError ?? this.nameError),
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );
}
