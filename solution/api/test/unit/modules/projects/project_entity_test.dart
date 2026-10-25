import 'package:devtasks_api/modules/projects/domain/project_entity.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectEntity (EPIC-03 · F3.1)', () {
    test('armazena atributos imutáveis', () {
      final now = DateTime.utc(2026, 10, 24, 12, 34, 56);
      final entity = ProjectEntity(
        id: '00000000-0000-4000-8000-000000000002',
        workspaceId: '00000000-0000-4000-8000-000000000001',
        name: 'Meu Projeto',
        createdAt: now,
      );
      expect(entity.id, '00000000-0000-4000-8000-000000000002');
      expect(entity.workspaceId, '00000000-0000-4000-8000-000000000001');
      expect(entity.name, 'Meu Projeto');
      expect(entity.isArchived, isFalse);
    });

    test('isArchived reflete presença de archivedAt e toJson serializa ISO8601', () {
      final now = DateTime.utc(2026, 10, 24, 12, 0);
      final archived = DateTime.utc(2026, 10, 24, 22, 30);
      final entity = ProjectEntity(
        id: 'proj-1',
        workspaceId: 'ws-1',
        name: 'Projeto Arquivado',
        createdAt: now,
        archivedAt: archived,
      );

      expect(entity.isArchived, isTrue);
      expect(entity.toJson()['archivedAt'], '2026-10-24T22:30:00.000Z');
    });
  });
}