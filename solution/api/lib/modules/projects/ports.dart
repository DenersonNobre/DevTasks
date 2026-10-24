import 'domain/project_entity.dart';

/// Porta de persistência de Projetos (DIP · ISP).
///
/// IDs são String (UUID) conforme contrato OpenAPI e schema PostgreSQL.
abstract interface class ProjectRepository {
  /// Busca um projeto por ID.
  Future<ProjectEntity?> findById(String projectId);

  /// Cria um projeto dentro do workspace informado.
  Future<ProjectEntity> create({
    required String workspaceId,
    required String name,
  });

  /// Atualiza o nome de um projeto existente (`null` se não existir).
  Future<ProjectEntity?> updateName({
    required String projectId,
    required String name,
  });

  /// Lista os projetos de um workspace.
  Future<List<ProjectEntity>> listByWorkspace(String workspaceId);
}