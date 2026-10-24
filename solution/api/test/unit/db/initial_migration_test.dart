import 'dart:io';

import 'package:test/test.dart';

/// Verificação textual da migration inicial (sem banco).
///
/// Prova que o schema versionado declara as 5 tabelas e as cercas de invariante.
/// A prova comportamental exige Postgres real e vive em `test/integration/db/`.
void main() {
  late String sql;

  setUpAll(() {
    final file = File('migrations/0001_initial.sql');
    expect(file.existsSync(), isTrue, reason: 'migration inicial ausente');
    sql = file.readAsStringSync();
  });

  group('UC-08.02 — schema inicial', () {
    test('declara as 5 tabelas do domínio', () {
      for (final table in [
        'devtasks_user',
        'devtasks_session',
        'devtasks_workspace',
        'devtasks_workspace_member',
        'devtasks_project',
      ]) {
        expect(
          sql,
          contains('CREATE TABLE $table'),
          reason: 'tabela ausente: $table',
        );
      }
    });

    test('e-mail é único (INV-08)', () {
      expect(sql, contains('UNIQUE (email)'));
    });

    test('token de sessão é único e ligado ao usuário (INV-SEC-17)', () {
      expect(sql, contains('UNIQUE (token_hash)'));
      expect(
        sql,
        contains('user_id    bigint      NOT NULL REFERENCES devtasks_user (id)'),
      );
    });

    test('papel é restrito a owner|developer|viewer (INV-06)', () {
      expect(sql, contains("CHECK (role IN ('owner', 'developer', 'viewer'))"));
    });

    test('membership é única por (workspace, usuário) (INV-09)', () {
      expect(sql, contains('UNIQUE (workspace_id, user_id)'));
    });

    test('projeto referencia workspace com cascata (INV-01)', () {
      expect(
        sql,
        contains('workspace_id bigint NOT NULL REFERENCES devtasks_workspace (id) ON DELETE CASCADE'),
      );
    });

    test('índices de consulta por dono existem', () {
      expect(sql, contains('devtasks_session_user_id_idx'));
      expect(sql, contains('devtasks_workspace_member_user_id_idx'));
      expect(sql, contains('devtasks_project_workspace_id_idx'));
    });
  });
}
