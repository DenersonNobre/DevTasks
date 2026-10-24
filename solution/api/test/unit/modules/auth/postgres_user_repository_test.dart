import 'package:devtasks_api/core/db/sql_executor.dart';
import 'package:devtasks_api/modules/auth/infrastructure/postgres_user_repository.dart';
import 'package:devtasks_api/modules/auth/ports.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

class _FakeUniqueViolationException implements ServerException {
  @override
  String get code => '23505';

  @override
  String get message => 'duplicate key value violates unique constraint';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockSqlExecutor implements ISqlExecutor {
  String? lastSql;
  Map<String, Object?>? lastParameters;
  List<Map<String, Object?>> queryResult = [];
  Exception? throwOnQuery;

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
    if (throwOnQuery != null) {
      throw throwOnQuery!;
    }
    return queryResult;
  }
}

void main() {
  group('PostgresUserRepository (D-08 / UC-08.03)', () {
    late _MockSqlExecutor sql;
    late PostgresUserRepository repository;

    setUp(() {
      sql = _MockSqlExecutor();
      repository = PostgresUserRepository(sql);
    });

    test('existsByEmail consulta por e-mail normalizado e retorna true se houver registro', () async {
      sql.queryResult = [{'exists': 1}];

      final exists = await repository.existsByEmail('user@test.com');

      expect(exists, isTrue);
      expect(sql.lastParameters, {'email': 'user@test.com'});
      expect(sql.lastSql, contains('devtasks_user'));
    });

    test('existsByEmail retorna false se vazio', () async {
      sql.queryResult = [];

      final exists = await repository.existsByEmail('none@test.com');

      expect(exists, isFalse);
    });

    test('create insere usuário com sucesso e retorna UserCreated', () async {
      sql.queryResult = [
        {
          'id': '11111111-1111-1111-1111-111111111111',
          'name': 'Ana',
          'email': 'ana@test.com',
        }
      ];

      final outcome = await repository.create(
        name: 'Ana',
        email: 'ana@test.com',
        passwordHash: 'hash-abc',
      );

      expect(outcome, isA<UserCreated>());
      final created = (outcome as UserCreated).user;
      expect(created.id, '11111111-1111-1111-1111-111111111111');
      expect(created.name, 'Ana');
      expect(created.email, 'ana@test.com');
      expect(created.emailVerified, isFalse);
    });

    test('create mapeia ServerException 23505 para EmailTaken (INV-08)', () async {
      sql.throwOnQuery = _FakeUniqueViolationException();

      final outcome = await repository.create(
        name: 'Ana',
        email: 'ana@test.com',
        passwordHash: 'hash-abc',
      );

      expect(outcome, isA<EmailTaken>());
    });

    test('findById retorna UserProfile quando usuário existe', () async {
      sql.queryResult = [
        {
          'id': 'user-123',
          'name': 'Carlos',
          'email': 'carlos@test.com',
        }
      ];

      final profile = await repository.findById('user-123');

      expect(profile, isNotNull);
      expect(profile!.userId, 'user-123');
      expect(profile.name, 'Carlos');
      expect(profile.email, 'carlos@test.com');
      expect(profile.toJson(), {
        'userId': 'user-123',
        'name': 'Carlos',
        'email': 'carlos@test.com',
      });
    });

    test('findById retorna null quando usuário não existe', () async {
      sql.queryResult = [];

      final profile = await repository.findById('missing');

      expect(profile, isNull);
    });

    test('findByEmail retorna CredentialRecord com hash de senha', () async {
      sql.queryResult = [
        {
          'id': 'user-456',
          'email': 'user@domain.com',
          'password_hash': 'stored-secret-hash',
        }
      ];

      final record = await repository.findByEmail('user@domain.com');

      expect(record, isNotNull);
      expect(record!.id, 'user-456');
      expect(record.email, 'user@domain.com');
      expect(record.passwordHash, 'stored-secret-hash');
    });

    test('findEmailById retorna email do usuário', () async {
      sql.queryResult = [{'email': 'owner@test.com'}];

      final email = await repository.findEmailById('user-789');

      expect(email, 'owner@test.com');
      expect(sql.lastParameters, {'id': 'user-789'});
    });
  });
}
