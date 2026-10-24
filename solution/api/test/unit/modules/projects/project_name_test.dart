import 'package:devtasks_api/src/modules/projects/domain/project_name.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectName Value Object (UC-03.01)', () {
    test('cria nome válido com trim', () {
      final parsed = ProjectName.parse('  Meu Projeto Backend  ');
      expect(parsed.error, isNull);
      expect(parsed.name, isNotNull);
      expect(parsed.name!.value, 'Meu Projeto Backend');
    });

    test('rejeita nome vazio ou composto apenas por espaços', () {
      final p1 = ProjectName.parse('');
      expect(p1.name, isNull);
      expect(p1.error, 'O nome do projeto é obrigatório.');

      final p2 = ProjectName.parse('     ');
      expect(p2.name, isNull);
      expect(p2.error, 'O nome do projeto é obrigatório.');
    });

    test('rejeita nome maior que 100 caracteres', () {
      final longName = 'P' * 101;
      final parsed = ProjectName.parse(longName);
      expect(parsed.name, isNull);
      expect(parsed.error, 'O nome do projeto deve ter até 100 caracteres.');
    });
  });
}
