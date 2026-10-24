import 'dart:io';

import 'package:devtasks_api/devtasks_api.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('devtasks_migrations_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  File write(String name, String content) {
    final file = File('${tempDir.path}${Platform.pathSeparator}$name');
    file.writeAsStringSync(content);
    return file;
  }

  group('UC-08.02 — loadMigrations', () {
    test('lê versão e nome do padrão <versao>_<nome>.sql', () {
      write('0001_initial.sql', 'CREATE TABLE a ();');

      final migrations = loadMigrations(tempDir);

      expect(migrations, hasLength(1));
      expect(migrations.single.version, '0001');
      expect(migrations.single.name, 'initial');
      expect(migrations.single.sql, contains('CREATE TABLE'));
    });

    test('ordena por versão independente da ordem de criação', () {
      write('0010_terceira.sql', '-- 3');
      write('0002_segunda.sql', '-- 2');
      write('0001_primeira.sql', '-- 1');

      final versions = loadMigrations(tempDir).map((m) => m.version);

      expect(versions, ['0001', '0002', '0010']);
    });

    test('ignora arquivos que não são .sql', () {
      write('0001_initial.sql', '-- ok');
      write('README.md', '# nota');

      expect(loadMigrations(tempDir), hasLength(1));
    });

    test('diretório inexistente devolve lista vazia', () {
      final missing = Directory('${tempDir.path}${Platform.pathSeparator}nao_existe');

      expect(loadMigrations(missing), isEmpty);
    });

    test('nome sem separador é recusado', () {
      write('initial.sql', '-- sem versão');

      expect(
        () => loadMigrations(tempDir),
        throwsA(isA<MigrationFormatException>()),
      );
    });

    test('versão não numérica é recusada', () {
      write('abc_initial.sql', '-- versão inválida');

      expect(
        () => loadMigrations(tempDir),
        throwsA(isA<MigrationFormatException>()),
      );
    });

    test('versão duplicada em arquivos distintos é recusada', () {
      write('0001_a.sql', '-- a');
      write('0001_b.sql', '-- b');

      expect(
        () => loadMigrations(tempDir),
        throwsA(isA<MigrationFormatException>()),
      );
    });
  });
}
