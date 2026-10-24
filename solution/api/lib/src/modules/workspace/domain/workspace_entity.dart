import 'workspace_member_role.dart';

/// Entidade de domínio representando o Workspace (SPEC §4.1).
///
/// O id segue o contrato OpenAPI (formato uuid) — identificado por String.
class WorkspaceEntity {
  const WorkspaceEntity({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final String id;
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

  /// Serializa para JSON (sem DTO de transporte no domínio).
  Map<String, Object?> toJson() {
    return {
      'id': workspace.id,
      'name': workspace.name,
      'role': role.wireValue,
      'createdAt': workspace.createdAt.toUtc().toIso8601String(),
    };
  }
}