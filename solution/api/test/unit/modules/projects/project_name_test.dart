import 'package:devtasks_api/src/modules/projects/domain/project_name.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectName Value Object (UC-03.01)', () {
    test('cria nome válido com trim', () {
      final parsed = ProjectName.parse('  Meu Projeto  ');
      expect(parsed.error, isNull);
      expect(parsed.name, isNotNull);
      expect(parsed.name!.value, 'Meu Projeto');
    });

    test('rejeita nome vazio', () {
      final parsed = ProjectName.parse('');
      expect(parsed.error, 'O nome do projeto é obrigatório.');
      expect(parsed.name, isNull);
    });

    test('rejeita nome maior que 100 caracteres', () {
      final longName = 'A' * 101;
      final parsed = ProjectName.parse(longName);
      expect(parsed.error, 'O nome do projeto deve ter até 100 caracteres.');
      expect(parsed.name, isNull);
    });


  });
}