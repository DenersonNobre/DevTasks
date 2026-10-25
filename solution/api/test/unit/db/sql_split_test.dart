import 'package:devtasks_api/devtasks_api.dart';
import 'package:test/test.dart';

void main() {
  group('splitSqlStatements', () {
    test('divide statements simples separados por ponto-e-vírgula', () {
      const sql = 'CREATE TABLE a (id int); CREATE TABLE b (id int);';
      final statements = splitSqlStatements(sql);
      expect(statements, [
        'CREATE TABLE a (id int)',
        'CREATE TABLE b (id int)',
      ]);
    });

    test('preserva ponto-e-vírgula dentro de literais de string', () {
      const sql = "INSERT INTO t (val) VALUES ('um; dois; tres');";
      final statements = splitSqlStatements(sql);
      expect(statements, [
        "INSERT INTO t (val) VALUES ('um; dois; tres')",
      ]);
    });

    test('preserva ponto-e-vírgula dentro de comentários de linha e de bloco', () {
      const sql = '''
-- Comentário com ; ponto e vírgula
CREATE TABLE t (id int);
/* Comentário bloco
com ; múltiplos pontos;
*/
CREATE TABLE u (id int);
''';
      final statements = splitSqlStatements(sql);
      expect(statements, hasLength(2));
      expect(statements[0], contains('CREATE TABLE t'));
      expect(statements[1], contains('CREATE TABLE u'));
    });

    test('preserva ponto-e-vírgula dentro de dollar-quotes', () {
      const sql = r'''
CREATE OR REPLACE FUNCTION test_fn() RETURNS void AS $$
BEGIN
  PERFORM 1;
END;
$$ LANGUAGE plpgsql;
''';
      final statements = splitSqlStatements(sql);
      expect(statements, hasLength(1));
      expect(statements[0], contains(r'$$ LANGUAGE plpgsql'));
    });

    test('retorna lista vazia para script vazio ou de apenas espaços/comentários', () {
      expect(splitSqlStatements(''), isEmpty);
      expect(splitSqlStatements('   \n\t  '), isEmpty);
      expect(splitSqlStatements('-- apenas comentário\n'), isEmpty);
    });
  });
}
