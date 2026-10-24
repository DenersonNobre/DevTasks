import 'package:devtasks_api/src/modules/projects/domain/project_entity.dart';
import 'package:devtasks_api/src/modules/projects/ports.dart';
import 'package:test/test.dart';

class _FakeProjectRepository implements ProjectRepository {
  final List<ProjectEntity> projects = [];

  @override
  Future<ProjectEntity> create({
    required int workspaceId,
    required String name,
  }) async {
    final entity = ProjectEntity(
      id: projects.length + 1,
      workspaceId: workspaceId,
      name: name,
      createdAt: DateTime.utc(2026, 10, 24, 12, 0, 0),
    );
    projects.add(entity);
    return entity;
  }

  @override
  Future<ProjectEntity?> findById(int projectId) async {
    try {
      return projects.firstWhere((p) => p.id == projectId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ProjectEntity>> listActiveByWorkspace(int workspaceId) async {
    return projects.where((p) => p.workspaceId == workspaceId).toList();
  }

  @override
  Future<ProjectEntity?> updateName({
    required int projectId,
    required String name,
  }) async {
    final index = projects.indexWhere((p) => p.id == projectId);
    if (index == -1) return null;
    final updated = ProjectEntity(
      id: projectId,
      workspaceId: projects[index].workspaceId,
      name: name,
      createdAt: projects[index].createdAt,
    );
    projects[index] = updated;
    return updated;
  }
}

void main() {
  group('ProjectEntity & ProjectRepository Port (EPIC-03 / F3.1)', () {
    test('ProjectEntity construtor imutável armazena atributos corretos', () {
      final now = DateTime.utc(2026, 10, 24, 12, 0, 0);
      final project = ProjectEntity(
        id: 10,
        workspaceId: 5,
        name: 'API Core',
        createdAt: now,
      );

      expect(project.id, 10);
      expect(project.workspaceId, 5);
      expect(project.name, 'API Core');
      expect(project.createdAt, now);
    });

    test('ProjectRepository port permite CRUD via fake em memória', () async {
      final repo = _FakeProjectRepository();

      final created = await repo.create(
        workspaceId: 1,
        name: 'Projeto 1',
      );

      expect(created.id, 1);
      expect(created.workspaceId, 1);
      expect(created.name, 'Projeto 1');

      final found = await repo.findById(1);
      expect(found, isNotNull);
      expect(found!.name, 'Projeto 1');

      final notFound = await repo.findById(999);
      expect(notFound, isNull);

      final updated = await repo.updateName(projectId: 1, name: 'Projeto Renomeado');
      expect(updated, isNotNull);
      expect(updated!.name, 'Projeto Renomeado');

      final list = await repo.listActiveByWorkspace(1);
      expect(list.length, 1);
      expect(list.first.name, 'Projeto Renomeado');
    });
  });
}
