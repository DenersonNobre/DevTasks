import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'domain/project_entity.dart';
import 'ports.dart';

/// Implementação do [ProjectRepository] sobre o ORM do Serverpod.
class ServerpodProjectRepository implements ProjectRepository {
  const ServerpodProjectRepository(this._session);

  final Session _session;

  @override
  Future<ProjectEntity?> findById(int projectId) async {
    final record = await DevtasksProject.db.findById(_session, projectId);
    if (record == null || record.id == null) return null;
    return _toEntity(record);
  }

  @override
  Future<ProjectEntity> create({
    required int workspaceId,
    required String name,
  }) async {
    final record = DevtasksProject(
      workspaceId: workspaceId,
      name: name,
      createdAt: DateTime.now().toUtc(),
    );
    final saved = await DevtasksProject.db.insertRow(_session, record);
    return _toEntity(saved);
  }

  @override
  Future<ProjectEntity?> updateName({
    required int projectId,
    required String name,
  }) async {
    final record = await DevtasksProject.db.findById(_session, projectId);
    if (record == null) return null;

    record.name = name;
    final updated = await DevtasksProject.db.updateRow(_session, record);
    return _toEntity(updated);
  }

  @override
  Future<List<ProjectEntity>> listActiveByWorkspace(int workspaceId) async {
    final rows = await DevtasksProject.db.find(
      _session,
      where: (t) => t.workspaceId.equals(workspaceId),
      orderBy: (t) => t.createdAt,
    );
    return rows.map(_toEntity).toList();
  }

  ProjectEntity _toEntity(DevtasksProject record) => ProjectEntity(
    id: record.id!,
    workspaceId: record.workspaceId,
    name: record.name,
    createdAt: record.createdAt,
  );
}
