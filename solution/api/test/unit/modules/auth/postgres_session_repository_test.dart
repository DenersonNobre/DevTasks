import 'package:devtasks_api/core/db/sql_executor.dart';
import 'package:devtasks_api/modules/auth/infrastructure/postgres_session_repository.dart';
import 'package:devtasks_api/modules/auth/ports.dart';
import 'package:test/test.dart';

class _MockSqlExecutor implements ISqlExecutor {
  String? lastSql;
  Map<String, Object?>? lastParameters;
  List<Map<String, Object?>> queryResult = [];

  @override
  Future<void> execute(String sql, {Map<String, Object?>? parameters}) async {
    lastSql = sql;
    lastParameters = parameters;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String sql, {
    Map<String, Object?>? parameters,
  }) async {
    lastSql = sql;
    lastParameters = parameters;
    return queryResult;
  }
}

void main() {
  group('PostgresSessionRepository (D-08 / INV-SEC-17 / UC-08.03)', () {
    late _MockSqlExecutor sql;
    late PostgresSessionRepository repository;

    setUp(() {
      sql = _MockSqlExecutor();
      repository = PostgresSessionRepository(sql);
    });

    test('save insere registro de sessão com token_hash e timestamp', () async {
      final now = DateTime.utc(2026, 10, 24, 12, 0);
      final expires = now.add(const Duration(hours: 24));
      final record = SessionRecord(
        userId: '22222222-2222-2222-2222-222222222222',
        tokenHash: 'sha256-hash-value',
        createdAt: now,
        expiresAt: expires,
      );

      await repository.save(record);

      expect(sql.lastSql, contains('INSERT INTO devtasks_session'));
      expect(sql.lastParameters, {
        'userId': '22222222-2222-2222-2222-222222222222',
        'tokenHash': 'sha256-hash-value',
        'expiresAt': expires,
        'createdAt': now,
        'revokedAt': null,
      });
    });

    test('findByTokenHash retorna SessionRecord quando sessão existe', () async {
      final now = DateTime.utc(2026, 10, 24, 12, 0);
      final expires = now.add(const Duration(hours: 24));
      sql.queryResult = [
        {
          'user_id': 'user-uuid',
          'token_hash': 'sha256-hash-val',
          'created_at': now,
          'expires_at': expires,
          'revoked_at': null,
        }
      ];

      final session = await repository.findByTokenHash('sha256-hash-val');

      expect(session, isNotNull);
      expect(session!.userId, 'user-uuid');
      expect(session.tokenHash, 'sha256-hash-val');
      expect(session.isExpired(now.add(const Duration(hours: 1))), isFalse);
      expect(session.isRevoked, isFalse);
    });

    test('findByTokenHash retorna null quando sessão não existe', () async {
      sql.queryResult = [];

      final session = await repository.findByTokenHash('missing-hash');

      expect(session, isNull);
    });

    test('revokeByTokenHash atualiza revoked_at onde token_hash confere', () async {
      final revokedAt = DateTime.utc(2026, 10, 24, 13, 0);

      await repository.revokeByTokenHash('sha256-hash-val', revokedAt);

      expect(sql.lastSql, contains('UPDATE devtasks_session'));
      expect(sql.lastSql, contains('SET revoked_at = @revokedAt'));
      expect(sql.lastParameters, {
        'tokenHash': 'sha256-hash-val',
        'revokedAt': revokedAt,
      });
    });
  });
}

