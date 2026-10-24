// solution/app/lib/modules/projects/presentation/.presentation.dart
// Barrel pontuado da apresentação de projetos (D-07).
// Exporta estados/status e a View: os ViewModels importam este barrel, então
// exportá-los aqui criaria ciclo.

export 'projects_state.dart' show ProjectsState, ProjectsStatus;
export 'projects_view.dart' show ProjectsView;
