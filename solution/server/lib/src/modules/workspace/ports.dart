import '../../generated/protocol.dart';
import 'domain/workspace_entity.dart';

/// Porta de persistência de Workspace e suas filiações (SPEC §5).
abstract interface class WorkspaceRepository {
  /// Busca um workspace por ID (independente de autorização).
  Future<WorkspaceEntity?> findById(int id);

  /// Cria um workspace e vincula o usuário criador como `owner` na mesma transação atômica.
  Future<WorkspaceWithRole> createWithRole({
    required String name,
    required String ownerUserId,
  });

  /// Lista todos os workspaces nos quais o usuário é membro ativo com seus respectivos papéis.
  Future<List<WorkspaceWithRole>> listByUserId(String userId);

  /// Obtém o papel de filiação de um usuário em determinado workspace (`null` se não-membro).
  Future<WorkspaceMemberRole?> getMemberRole({
    required int workspaceId,
    required String userId,
  });

  /// Atualiza o nome de um workspace.
  Future<WorkspaceEntity?> updateName({
    required int workspaceId,
    required String name,
  });
}

