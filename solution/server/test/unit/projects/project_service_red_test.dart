import 'package:devtasks_server/src/generated/protocol.dart';
import 'package:devtasks_server/src/modules/projects/domain/project_entity.dart';
import 'package:devtasks_server/src/modules/projects/ports.dart';
import 'package:devtasks_server/src/modules/projects/project_service.dart';
import 'package:devtasks_server/src/modules/workspace/domain/workspace_entity.dart';
import 'package:devtasks_server/src/modules/workspace/ports.dart';
import 'package:test/test.dart';

/// Repositório fake de projetos em memória.
class _FakeProjectRepository implements ProjectRepository {
  _FakeProjectRepository(this._projects, {this.nextId = 100});

  final List<ProjectEntity> _projects;
  int nextId;

  @override
  Future<ProjectEntity?> findById(int id) async {
    for (final p in _projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<ProjectEntity> create({
    required int workspaceId,
    required String name,
  }) async {
    final created = ProjectEntity(
      id: nextId++,
      workspaceId: workspaceId,
      name: name,
      createdAt: DateTime.utc(2026, 10, 24),
    );
    _projects.add(created);
    return created;
  }

  @override
  Future<ProjectEntity?> updateName({
    required int projectId,
    required String name,
  }) async {
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index < 0) return null;
    final current = _projects[index];
    final updated = ProjectEntity(
      id: current.id,
      workspaceId: current.workspaceId,
      name: name,
      createdAt: current.createdAt,
    );
    _projects[index] = updated;
    return updated;
  }

  @override
  Future<List<ProjectEntity>> listActiveByWorkspace(int workspaceId) async =>
      _projects.where((p) => p.workspaceId == workspaceId).toList();
}

/// Repositório fake de workspaces (apenas papéis, o que o guard consome).
class _FakeWorkspaceRepository implements WorkspaceRepository {
  _FakeWorkspaceRepository(this._roles, {this.existingWorkspaces = const {}});

  /// Chave: `workspaceId:userId` → papel.
  final Map<String, WorkspaceMemberRole> _roles;
  final Set<int> existingWorkspaces;

  @override
  Future<WorkspaceMemberRole?> getMemberRole({
    required int workspaceId,
    required String userId,
  }) async {
    if (existingWorkspaces.isNotEmpty && !existingWorkspaces.contains(workspaceId)) {
      return null;
    }
    return _roles['$workspaceId:$userId'];
  }

  @override
  Future<WorkspaceEntity?> findById(int id) async => null;

  @override
  Future<WorkspaceWithRole> createWithRole({
    required String name,
    required String ownerUserId,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<WorkspaceWithRole>> listByUserId(String userId) async => const [];

  @override
  Future<WorkspaceEntity?> updateName({
    required int workspaceId,
    required String name,
  }) async =>
      null;

  @override
  Future<WorkspaceWithRole> addMember({
    required int workspaceId,
    required String userId,
    required WorkspaceMemberRole role,
  }) =>
      throw UnimplementedError();

  @override
  Future<bool> removeMember({
    required int workspaceId,
    required String userId,
  }) async =>
      false;
}

void main() {
  const acme = 7;
  const outro = 8;

  late List<ProjectEntity> projects;
  late ProjectService service;

  void buildService({
    Map<String, WorkspaceMemberRole> roles = const {},
    Set<int> existing = const {acme, outro},
  }) {
    service = ProjectService(
      projects: _FakeProjectRepository(projects),
      workspaces: _FakeWorkspaceRepository(
        roles,
        existingWorkspaces: existing,
      ),
    );
  }

  setUp(() {
    projects = <ProjectEntity>[];
  });

  group('UC-03.01 — criação de projeto (INV-06 / INV-01)', () {
    test('owner cria projeto no próprio workspace', () async {
      buildService(roles: {'$acme:carla': WorkspaceMemberRole.owner});

      final result = await service.createProject(
        callerUserId: 'carla',
        workspaceId: acme,
        name: 'App Mobile',
      );

      expect(result.success, isTrue);
      expect(result.project?.name, 'App Mobile');
      expect(result.project?.workspaceId, acme);
      expect(projects, hasLength(1));
    });

    test('developer recebe ERR_INSUFFICIENT_ROLE (INV-06)', () async {
      buildService(roles: {'$acme:rafa': WorkspaceMemberRole.developer});

      final result = await service.createProject(
        callerUserId: 'rafa',
        workspaceId: acme,
        name: 'App Mobile',
      );

      expect(result.success, isFalse);
      expect(result.errorCode, ProjectErrorCodes.insufficientRole);
      expect(projects, isEmpty);
    });

    test('viewer recebe ERR_INSUFFICIENT_ROLE (INV-06)', () async {
      buildService(roles: {'$acme:lia': WorkspaceMemberRole.viewer});

      final result = await service.createProject(
        callerUserId: 'lia',
        workspaceId: acme,
        name: 'App Mobile',
      );

      expect(result.success, isFalse);
      expect(result.errorCode, ProjectErrorCodes.insufficientRole);
      expect(projects, isEmpty);
    });

    test(
      'não-membro e workspace inexistente devolvem o MESMO ERR_NOT_FOUND (INV-01)',
      () async {
        buildService(roles: {'$acme:carla': WorkspaceMemberRole.owner});

        final nonMember = await service.createProject(
          callerUserId: 'estranho',
          workspaceId: acme,
          name: 'App Mobile',
        );
        final inexistent = await service.createProject(
          callerUserId: 'estranho',
          workspaceId: 999,
          name: 'App Mobile',
        );

        expect(nonMember.success, isFalse);
        expect(inexistent.success, isFalse);
        expect(nonMember.errorCode, ProjectErrorCodes.notFound);
        expect(inexistent.errorCode, ProjectErrorCodes.notFound);
        expect(inexistent.errorCode, nonMember.errorCode);
        expect(projects, isEmpty);
      },
    );

    test('nome inválido devolve ERR_VALIDATION sem gravar nada', () async {
      buildService(roles: {'$acme:carla': WorkspaceMemberRole.owner});

      final result = await service.createProject(
        callerUserId: 'carla',
        workspaceId: acme,
        name: '   ',
      );

      expect(result.success, isFalse);
      expect(result.errorCode, ProjectErrorCodes.validation);
      expect(projects, isEmpty);
    });
  });

  group('UC-03.01 — edição de projeto (INV-06 / INV-01)', () {
    test('owner renomeia projeto do seu workspace', () async {
      final existing = ProjectEntity(
        id: 1,
        workspaceId: acme,
        name: 'Antigo',
        createdAt: DateTime.utc(2026, 10, 24),
      );
      projects.add(existing);
      buildService(roles: {'$acme:carla': WorkspaceMemberRole.owner});

      final result = await service.updateProject(
        callerUserId: 'carla',
        projectId: existing.id,
        name: 'Novo',
      );

      expect(result.success, isTrue);
      expect(result.project?.name, 'Novo');
    });

    test('developer do próprio workspace recebe ERR_INSUFFICIENT_ROLE (INV-06)', () async {
      final existing = ProjectEntity(
        id: 1,
        workspaceId: acme,
        name: 'Antigo',
        createdAt: DateTime.utc(2026, 10, 24),
      );
      projects.add(existing);
      buildService(roles: {'$acme:rafa': WorkspaceMemberRole.developer});

      final result = await service.updateProject(
        callerUserId: 'rafa',
        projectId: existing.id,
        name: 'Novo',
      );

      expect(result.success, isFalse);
      expect(result.errorCode, ProjectErrorCodes.insufficientRole);
      expect(projects.single.name, 'Antigo');
    });

    test(
      'projeto de outro workspace é indistinguível de inexistente (INV-01)',
      () async {
        final alheio = ProjectEntity(
          id: 1,
          workspaceId: outro,
          name: 'Secreto',
          createdAt: DateTime.utc(2026, 10, 24),
        );
        projects.add(alheio);
        buildService(roles: {'$acme:carla': WorkspaceMemberRole.owner});

        final crossTenant = await service.updateProject(
          callerUserId: 'carla',
          projectId: alheio.id,
          name: 'Invasão',
        );
        final inexistent = await service.updateProject(
          callerUserId: 'carla',
          projectId: 4242,
          name: 'Invasão',
        );

        expect(crossTenant.success, isFalse);
        expect(inexistent.success, isFalse);
        expect(crossTenant.errorCode, ProjectErrorCodes.notFound);
        expect(inexistent.errorCode, crossTenant.errorCode);
      },
    );
  });

  group('UC-03.01 — listagem de projetos (INV-01)', () {
    test('membro lista apenas os projetos ativos do seu workspace', () async {
      projects.addAll([
        ProjectEntity(
          id: 1,
          workspaceId: acme,
          name: 'Da Acme',
          createdAt: DateTime.utc(2026, 10, 24),
        ),
        ProjectEntity(
          id: 2,
          workspaceId: outro,
          name: 'De Outro',
          createdAt: DateTime.utc(2026, 10, 24),
        ),
      ]);
      buildService(roles: {'$acme:rafa': WorkspaceMemberRole.developer});

      final result = await service.listProjects(
        callerUserId: 'rafa',
        workspaceId: acme,
      );

      expect(result.success, isTrue);
      expect(result.projects.map((p) => p.name), ['Da Acme']);
    });

    test('não-membro recebe ERR_NOT_FOUND ao listar (INV-01)', () async {
      buildService(roles: {'$acme:carla': WorkspaceMemberRole.owner});

      final result = await service.listProjects(
        callerUserId: 'estranho',
        workspaceId: acme,
      );

      expect(result.success, isFalse);
      expect(result.errorCode, ProjectErrorCodes.notFound);
    });
  });
}
