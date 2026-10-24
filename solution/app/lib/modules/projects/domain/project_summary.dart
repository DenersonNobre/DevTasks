// solution/app/lib/modules/projects/domain/project_summary.dart
// VO de leitura de projeto no app (D-07 / UC-03.01).
// SRP: representar um projeto exibível. NÃO conhece DTO, HTTP, sessão nem Flutter (DIP).

/// Projeto exibível na listagem do workspace.
final class ProjectSummary {
  const ProjectSummary({
    required this.id,
    required this.workspaceId,
    required this.name,
  });

  final int id;
  final int workspaceId;
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectSummary &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, workspaceId, name);
}
