/// Entidade de domínio de Projeto (EPIC-03 · F3.1 / F3.2).
///
/// SRP: representa um projeto dentro de um workspace. Não conhece HTTP,
/// ORM, transporte nem autorização (DIP).
class ProjectEntity {
  const ProjectEntity({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.createdAt,
    this.archivedAt,
  });

  final String id;
  final String workspaceId;
  final String name;
  final DateTime createdAt;
  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  Map<String, Object?> toJson() => {
        'id': id,
        'workspaceId': workspaceId,
        'name': name,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'archivedAt': archivedAt?.toUtc().toIso8601String(),
      };
}
