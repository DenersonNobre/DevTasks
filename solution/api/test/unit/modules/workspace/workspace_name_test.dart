import 'package:devtasks_api/modules/workspace/domain/workspace_name.dart';
import 'package:test/test.dart';

void main() {
  group('WorkspaceName Value Object (SPEC §4.2)', () {
    test('cria nome válido com trim', () {
      final (name, error) = WorkspaceName.create('  Meu Workspace  ');
      expect(error, isNull);
      expect(name, isNotNull);
      expect(name!.value, 'Meu Workspace');
      expect(name.toString(), 'Meu Workspace');
    });

    test('rejeita nome nulo', () {
      final (name, error) = WorkspaceName.create(null);
      expect(name, isNull);
      expect(error, 'Nome do workspace é obrigatório.');
    });

    test('rejeita nome vazio ou composto apenas por espaços', () {
      final (name1, error1) = WorkspaceName.create('');
      expect(name1, isNull);
      expect(error1, 'Nome do workspace não pode ser vazio.');

      final (name2, error2) = WorkspaceName.create('    ');
      expect(name2, isNull);
      expect(error2, 'Nome do workspace não pode ser vazio.');
    });

    test('rejeita nome maior que 100 caracteres', () {
      final longName = 'A' * 101;
      final (name, error) = WorkspaceName.create(longName);
      expect(name, isNull);
      expect(error, 'Nome do workspace deve ter no máximo 100 caracteres.');
    });

    test('igualdade por valor e hashCode', () {
      final (w1, _) = WorkspaceName.create('DevTasks');
      final (w2, _) = WorkspaceName.create('DevTasks');
      final (w3, _) = WorkspaceName.create('Outro');

      expect(w1, equals(w2));
      expect(w1.hashCode, equals(w2.hashCode));
      expect(w1, isNot(equals(w3)));
    });
  });
}
