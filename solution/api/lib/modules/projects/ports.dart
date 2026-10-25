import 'domain/project_entity.dart';

/// Porta de persistência de Projetos (DIP · ISP).
///
/// IDs são String (UUID) conforme contrato OpenAPI e schema PostgreSQL.
abstract interface class IProjectRepository {
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
  ///
  /// Se [includeArchived] for `false` (padrão), retorna apenas projetos ativos (INV-05 / RF-08).
  Future<List<ProjectEntity>> listByWorkspace(
    String workspaceId, {
    bool includeArchived = false,
  });

  /// Arquiva um projeto tornando-o somente-leitura (INV-05 / RF-08).
  ///
  /// Idempotente: se já estiver arquivado, preserva o timestamp original e retorna a entidade.
  Future<ProjectEntity?> archive(String projectId);
}