import 'dart:io';

import 'package:devtasks_api/devtasks_api.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

/// Prova real das migrations contra PostgreSQL.
///
/// Sem `DEVTASKS_TEST_DATABASE_URL` o teste é **declaradamente pulado** — não
/// existe declaração de "persistência validada" sem banco (brief-22 §4).
void main() {
  final dsn = Platform.environment['DEVTASKS_TEST_DATABASE_URL'];
  final skipReason = dsn == null || dsn.isEmpty
      ? 'DEVTASKS_TEST_DATABASE_URL não definido (sem Postgres local)'
      : null;

  group('UC-08.02 — migrations contra Postgres real', () {
    late Pool<Session> pool;
    late SqlExecutor sql;
    late SqlMigrationStore store;
    late List<Migration> migrations;

    setUp(() async {
      pool = openPool(dsn!);
      sql = PgSqlExecutor(pool);
      store = SqlMigrationStore(sql);
      migrations = loadMigrations(Directory('migrations'));
      await sql.execute('DROP SCHEMA public CASCADE');
      await sql.execute('CREATE SCHEMA public');
    });

    tearDown(() async {
      await pool.close();
    });

    test('aplica todas as migrations e é idempotente', () async {
      final first = await Migrator(
        sql: sql,
        store: store,
        migrations: migrations,
      ).up();

      expect(first.applied, hasLength(migrations.length));

      final second = await Migrator(
        sql: sql,
        store: store,
        migrations: migrations,
      ).up();

      expect(second.applied, isEmpty);
      expect(second.skipped, migrations.length);
    });

    test('as 5 tabelas existem após aplicar', () async {
      await Migrator(sql: sql, store: store, migrations: migrations).up();

      final rows = await sql.query(
        "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'",
      );
      final tables = rows.map((row) => row['table_name']).toSet();

      expect(
        tables,
        containsAll([
          'devtasks_user',
          'devtasks_session',
          'devtasks_workspace',
          'devtasks_workspace_member',
          'devtasks_project',
        ]),
      );
    });

    test('UNIQUE de e-mail rejeita duplicata (INV-08)', () async {
      await Migrator(sql: sql, store: store, migrations: migrations).up();
      await sql.execute(
        "INSERT INTO devtasks_user (name, email, password_hash) VALUES ('A', 'a@x.com', 'h')",
      );

      expect(
        () => sql.execute(
          "INSERT INTO devtasks_user (name, email, password_hash) VALUES ('B', 'a@x.com', 'h')",
        ),
        throwsA(isA<UniqueViolationException>()),
      );
    });

    test('CHECK de papel rejeita valor fora de owner|developer|viewer (INV-06)', () async {
      await Migrator(sql: sql, store: store, migrations: migrations).up();
      await sql.execute(
        "INSERT INTO devtasks_user (name, email, password_hash) VALUES ('A', 'a@x.com', 'h')",
      );
      await sql.execute("INSERT INTO devtasks_workspace (name) VALUES ('W')");

      expect(
        () => sql.execute(
          'INSERT INTO devtasks_workspace_member (workspace_id, user_id, role) '
          "VALUES (1, 1, 'admin')",
        ),
        throwsA(isA<PgException>()),
      );
    });
  }, skip: skipReason);
}
