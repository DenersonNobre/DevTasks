import 'package:devtasks_server/src/generated/protocol.dart';
import 'package:devtasks_server/src/modules/workspace/domain/workspace_entity.dart';
import 'package:devtasks_server/src/modules/workspace/domain/workspace_name.dart';
import 'package:devtasks_server/src/modules/workspace/ports.dart';
import 'package:devtasks_server/src/modules/workspace/workspace_service.dart';
import 'package:test/test.dart';

class _FakeWorkspaceRepository implements WorkspaceRepository {
  final Map<int, WorkspaceEntity> workspaces = {};
  final List<DevtasksWorkspaceMember> members = [];
  int _nextId = 1;
  int transactionCalls = 0;

  @override
  Future<WorkspaceEntity?> findById(int id) async => workspaces[id];

  @override
  Future<WorkspaceWithRole> createWithRole({
    required String name,
    required String ownerUserId,
  }) async {
    transactionCalls++;
    final id = _nextId++;
    final ws = WorkspaceEntity(
      id: id,
      name: name,
      createdAt: DateTime.now().toUtc(),
    );
    workspaces[id] = ws;
    members.add(
      DevtasksWorkspaceMember(
        id: id,
        workspaceId: id,
        userId: ownerUserId,
        role: WorkspaceMemberRole.owner,
      ),
    );
    return WorkspaceWithRole(workspace: ws, role: WorkspaceMemberRole.owner);
  }

  @override
  Future<List<WorkspaceWithRole>> listByUserId(String userId) async {
    final userMemberships = members.where((m) => m.userId == userId);
    final result = <WorkspaceWithRole>[];
    for (final m in userMemberships) {
      final ws = workspaces[m.workspaceId];
      if (ws != null) {
        result.add(WorkspaceWithRole(workspace: ws, role: m.role));
      }
    }
    return result;
  }

  @override
  Future<WorkspaceMemberRole?> getMemberRole({
    required int workspaceId,
    required String userId,
  }) async {
    final match = members.cast<DevtasksWorkspaceMember?>().firstWhere(
          (m) => m!.workspaceId == workspaceId && m.userId == userId,
          orElse: () => null,
        );
    return match?.role;
  }

  @override
  Future<WorkspaceEntity?> updateName({
    required int workspaceId,
    required String name,
  }) async {
    final existing = workspaces[workspaceId];
    if (existing == null) return null;
    final updated = WorkspaceEntity(
      id: existing.id,
      name: name,
      createdAt: existing.createdAt,
    );
    workspaces[workspaceId] = updated;
    return updated;
  }
}

void main() {
  group('WorkspaceName Value Object', () {
    test('aceita nome válido com trim', () {
      final (vo, err) = WorkspaceName.create('  Meu Workspace  ');
      expect(err, isNull);
      expect(vo?.value, equals('Meu Workspace'));
    });

    test('rejeita nome vazio ou em branco com mensagem explicativa', () {
      final (vo1, err1) = WorkspaceName.create('');
      expect(vo1, isNull);
      expect(err1, contains('não pode ser vazio'));

      final (vo2, err2) = WorkspaceName.create('   ');
      expect(vo2, isNull);
      expect(err2, contains('não pode ser vazio'));

      final (vo3, err3) = WorkspaceName.create(null);
      expect(vo3, isNull);
      expect(err3, contains('obrigatório'));
    });

    test('rejeita nome que excede 100 caracteres', () {
      final longName = 'A' * 101;
      final (vo, err) = WorkspaceName.create(longName);
      expect(vo, isNull);
      expect(err, contains('no máximo 100 caracteres'));
    });
  });

  group('UC-02.01 — CRUD de Workspace (WorkspaceService)', () {
    late _FakeWorkspaceRepository repo;
    late WorkspaceService service;

    setUp(() {
      repo = _FakeWorkspaceRepository();
      service = WorkspaceService(repo);
    });

    group('Criação atômica e atribuição de owner (INV-06 / INV-09)', () {
      test('criação persiste workspace e membro owner na mesma operação', () async {
        final result = await service.createWorkspace(
          userId: 'user-1',
          name: 'Workspace Alpha',
        );

        expect(result.success, isTrue);
        expect(result.errorCode, isNull);
        expect(result.workspace, isNotNull);
        expect(result.workspace!.name, equals('Workspace Alpha'));
        expect(result.workspace!.role, equals(WorkspaceMemberRole.owner));

        // Prova atômica no repositório
        expect(repo.workspaces.containsKey(result.workspace!.id), isTrue);
        final member = repo.members.firstWhere((m) => m.workspaceId == result.workspace!.id);
        expect(member.userId, equals('user-1'));
        expect(member.role, equals(WorkspaceMemberRole.owner));
        expect(repo.transactionCalls, equals(1));
      });

      test('nome inválido devolve ERR_VALIDATION sem gravar nada', () async {
        final result = await service.createWorkspace(
          userId: 'user-1',
          name: '   ',
        );

        expect(result.success, isFalse);
        expect(result.errorCode, equals(WorkspaceErrorCodes.validation));
        expect(result.field, equals('name'));
        expect(repo.workspaces, isEmpty);
        expect(repo.members, isEmpty);
      });
    });

    group('Isolamento Multi-tenant e Indistinção (INV-01)', () {
      test('listagem de usuário A nunca devolve workspace de usuário B', () async {
        // user-1 cria workspace A
        final wsA = await service.createWorkspace(userId: 'user-1', name: 'WS de A');
        // user-2 cria workspace B
        final wsB = await service.createWorkspace(userId: 'user-2', name: 'WS de B');

        // Listagem de user-1
        final listA = await service.listWorkspaces(userId: 'user-1');
        expect(listA.success, isTrue);
        expect(listA.workspaces, hasLength(1));
        expect(listA.workspaces!.first.id, equals(wsA.workspace!.id));
        // Asserção explícita de ausência (não apenas tamanho)
        expect(
          listA.workspaces!.any((w) => w.id == wsB.workspace!.id),
          isFalse,
          reason: 'Workspace de B não pode vazar na listagem de A',
        );

        // Listagem de user-2
        final listB = await service.listWorkspaces(userId: 'user-2');
        expect(listB.success, isTrue);
        expect(listB.workspaces, hasLength(1));
        expect(listB.workspaces!.first.id, equals(wsB.workspace!.id));
        expect(
          listB.workspaces!.any((w) => w.id == wsA.workspace!.id),
          isFalse,
          reason: 'Workspace de A não pode vazar na listagem de B',
        );
      });

      test('não-membro e workspace inexistente recebem idêntico ERR_NOT_FOUND (indistinção)', () async {
        // user-1 cria workspace 1
        final ws = await service.createWorkspace(userId: 'user-1', name: 'WS Confidencial');

        // 1. user-2 tenta editar o workspace de user-1
        final resForeign = await service.updateWorkspace(
          userId: 'user-2',
          workspaceId: ws.workspace!.id,
          name: 'Nome Hackeado',
        );

        // 2. user-2 tenta editar workspace que sequer existe
        final resNonExistent = await service.updateWorkspace(
          userId: 'user-2',
          workspaceId: 999999,
          name: 'Nome Fantasma',
        );

        // Comprova indistinção perfeita de resposta (INV-01)
        expect(resForeign.success, isFalse);
        expect(resForeign.errorCode, equals(WorkspaceErrorCodes.notFound));
        expect(resForeign.message, equals('Workspace não encontrado.'));

        expect(resNonExistent.success, isFalse);
        expect(resNonExistent.errorCode, equals(WorkspaceErrorCodes.notFound));
        expect(resNonExistent.message, equals('Workspace não encontrado.'));
        expect(resForeign.errorCode, equals(resNonExistent.errorCode));
        expect(resForeign.message, equals(resNonExistent.message));
      });
    });

    group('Autorização por Papel (INV-06)', () {
      test('apenas owner pode renomear workspace; developer e viewer recebem ERR_INSUFFICIENT_ROLE', () async {
        final created = await service.createWorkspace(userId: 'owner-user', name: 'Original');
        final wsId = created.workspace!.id;

        // Adiciona developer e viewer ao workspace
        repo.members.add(
          DevtasksWorkspaceMember(
            id: 2,
            workspaceId: wsId,
            userId: 'dev-user',
            role: WorkspaceMemberRole.developer,
          ),
        );
        repo.members.add(
          DevtasksWorkspaceMember(
            id: 3,
            workspaceId: wsId,
            userId: 'viewer-user',
            role: WorkspaceMemberRole.viewer,
          ),
        );

        // Developer tenta renomear
        final resDev = await service.updateWorkspace(
          userId: 'dev-user',
          workspaceId: wsId,
          name: 'Renomeado por Dev',
        );
        expect(resDev.success, isFalse);
        expect(resDev.errorCode, equals(WorkspaceErrorCodes.insufficientRole));
        expect(resDev.message, contains('Permissão insuficiente'));

        // Viewer tenta renomear
        final resViewer = await service.updateWorkspace(
          userId: 'viewer-user',
          workspaceId: wsId,
          name: 'Renomeado por Viewer',
        );
        expect(resViewer.success, isFalse);
        expect(resViewer.errorCode, equals(WorkspaceErrorCodes.insufficientRole));

        // Owner renomeia com sucesso
        final resOwner = await service.updateWorkspace(
          userId: 'owner-user',
          workspaceId: wsId,
          name: 'Renomeado Oficialmente',
        );
        expect(resOwner.success, isTrue);
        expect(resOwner.workspace!.name, equals('Renomeado Oficialmente'));
        expect(repo.workspaces[wsId]!.name, equals('Renomeado Oficialmente'));
      });
    });
  });
}
