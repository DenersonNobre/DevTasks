import 'domain/project_entity.dart';

/// Porta de persistência de Projetos (DIP · ISP).
///
/// Apenas o que o caso de uso UC-03.01 consome. Sem tipos de infraestrutura.
abstract interface class ProjectRepository {
  /// Busca um projeto por ID, independente de autorização.
  Future<ProjectEntity?> findById(int projectId);

  /// Cria um projeto dentro do workspace informado.
  Future<ProjectEntity> create({
    required int workspaceId,
    required String name,
  });

  /// Atualiza o nome de um projeto existente (`null` se não existir).
  Future<ProjectEntity?> updateName({
    required int projectId,
    required String name,
  });

  /// Lista os projetos ativos de um workspace.
  Future<List<ProjectEntity>> listActiveByWorkspace(int workspaceId);
}
