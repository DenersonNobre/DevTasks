import 'workspace_member_role.dart';

/// Entidade de domínio representando o Workspace (SPEC §4.1).
class WorkspaceEntity {
  const WorkspaceEntity({
    required this.id,
    required this.name,
    this.createdAt,
  });

  final int id;
  final String name;
  final DateTime? createdAt;
}

/// Agregação de Workspace com o papel do usuário no contexto atual (D-02 / OpenAPI 3.1).
class WorkspaceWithRole {
  const WorkspaceWithRole({
    required this.workspace,
    required this.role,
  });

  final WorkspaceEntity workspace;
  final WorkspaceMemberRole role;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': workspace.id,
      'name': workspace.name,
      'role': role.wireValue,
      'createdAt': workspace.createdAt?.toUtc().toIso8601String(),
    };
  }
}

