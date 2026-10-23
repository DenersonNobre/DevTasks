import '../../../generated/protocol.dart';

/// Entidade de domínio representando o Workspace (SPEC §4.1).
class WorkspaceEntity {
  const WorkspaceEntity({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final int id;
  final String name;
  final DateTime createdAt;
}

/// Agregação de Workspace com o papel do usuário no contexto atual.
class WorkspaceWithRole {
  const WorkspaceWithRole({
    required this.workspace,
    required this.role,
  });

  final WorkspaceEntity workspace;
  final WorkspaceMemberRole role;

  WorkspaceDto toDto() {
    return WorkspaceDto(
      id: workspace.id,
      name: workspace.name,
      role: role,
      createdAt: workspace.createdAt,
    );
  }
}

