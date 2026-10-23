import 'package:devtasks_server/src/modules/auth/ports.dart';
import 'package:devtasks_server/src/modules/auth/serverpod_user_repository.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';
import 'package:test/test.dart';

final class _TestDatabaseQueryException extends DatabaseQueryException {
  _TestDatabaseQueryException({
    required this.message,
    this.code,
    this.tableName,
    this.constraintName,
  });

  @override
  final String message;

  @override
  final String? code;

  @override
  final String? tableName;

  @override
  final String? constraintName;

  @override
  String? get detail => null;

  @override
  String? get hint => null;

  @override
  String? get columnName => null;

  @override
  int? get position => null;
}

class _FakeServerpodAuthDbOperations implements ServerpodAuthDbOperations {
  _FakeServerpodAuthDbOperations({
    this.existingEmails = const {},
    this.throwOnInsertUserInfo,
    this.throwOnInsertEmailAuth,
  });

  final Set<String> existingEmails;
  final Object? throwOnInsertUserInfo;
  final Object? throwOnInsertEmailAuth;

  final List<UserInfo> insertedUserInfos = [];
  final List<EmailAuth> insertedEmailAuths = [];
  int _nextId = 1;

  @override
  Future<bool> emailAuthExists(Session session, String normalizedEmail) async {
    return existingEmails.contains(normalizedEmail);
  }

  @override
  Future<EmailAuth?> findEmailAuth(
    Session session,
    String normalizedEmail,
  ) async {
    if (!existingEmails.contains(normalizedEmail)) {
      return null;
    }
    return EmailAuth(
      id: 1,
      userId: 42,
      email: normalizedEmail,
      hash: r'$argon2id$v=19$m=19456,t=2,p=1$fakeSalt$fakeHash',
    );
  }

  @override
  Future<UserInfo> insertUserInfo(Session session, UserInfo userInfo) async {
    if (throwOnInsertUserInfo != null) {
      throw throwOnInsertUserInfo!;
    }
    final id = _nextId++;
    userInfo.id = id;
    insertedUserInfos.add(userInfo);
    return userInfo;
  }

  @override
  Future<EmailAuth> insertEmailAuth(
    Session session,
    EmailAuth emailAuth,
  ) async {
    if (throwOnInsertEmailAuth != null) {
      throw throwOnInsertEmailAuth!;
    }
    emailAuth.id = _nextId++;
    insertedEmailAuths.add(emailAuth);
    return emailAuth;
  }
}

// Session mock para testes puramente unitários sem conexão de banco de dados
class _FakeSession implements Session {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('ServerpodUserRepository — Mapeamento & TOCTOU (SQLSTATE 23505)', () {
    late _FakeSession fakeSession;

    setUp(() {
      fakeSession = _FakeSession();
    });

    test('existsByEmail consulta a existência do e-mail normalizado', () async {
      final ops = _FakeServerpodAuthDbOperations(
        existingEmails: {'user@example.com'},
      );
      final repo = ServerpodUserRepository(fakeSession, ops);

      expect(await repo.existsByEmail('user@example.com'), isTrue);
      expect(await repo.existsByEmail('other@example.com'), isFalse);
    });

    test('create persiste UserInfo e EmailAuth e devolve UserCreated com emailVerified=false',
        () async {
      final ops = _FakeServerpodAuthDbOperations();
      final repo = ServerpodUserRepository(fakeSession, ops);

      final outcome = await repo.create(
        name: 'Alice Silva',
        email: 'alice@example.com',
        passwordHash: 'hash-1234',
      );

      expect(outcome, isA<UserCreated>());
      final created = (outcome as UserCreated).user;
      expect(created.name, 'Alice Silva');
      expect(created.email, 'alice@example.com');
      expect(created.emailVerified, isFalse,
          reason: 'Novo cadastro nasce com emailVerified=false por padrão');

      expect(ops.insertedUserInfos.single.userName, 'Alice Silva');
      expect(ops.insertedUserInfos.single.email, 'alice@example.com');
      expect(ops.insertedEmailAuths.single.email, 'alice@example.com');
      expect(ops.insertedEmailAuths.single.hash, 'hash-1234');
      expect(ops.insertedEmailAuths.single.userId, ops.insertedUserInfos.single.id);
    });

    test('create captura SQLSTATE 23505 (unique_violation) e traduz para EmailTaken',
        () async {
      final ops = _FakeServerpodAuthDbOperations(
        throwOnInsertEmailAuth: _TestDatabaseQueryException(
          message: 'duplicate key value violates unique constraint "serverpod_email_auth_email"',
          code: '23505',
          tableName: 'serverpod_email_auth',
          constraintName: 'serverpod_email_auth_email',
        ),
      );
      final repo = ServerpodUserRepository(fakeSession, ops);

      final outcome = await repo.create(
        name: 'Bob',
        email: 'bob@example.com',
        passwordHash: 'hash-5678',
      );

      expect(outcome, isA<EmailTaken>());
    });

    test('create captura SQLSTATE 23505 também ao inserir UserInfo', () async {
      final ops = _FakeServerpodAuthDbOperations(
        throwOnInsertUserInfo: _TestDatabaseQueryException(
          message: 'duplicate key value violates unique constraint "serverpod_user_info_user_identifier"',
          code: '23505',
          tableName: 'serverpod_user_info',
        ),
      );
      final repo = ServerpodUserRepository(fakeSession, ops);

      final outcome = await repo.create(
        name: 'Bob',
        email: 'bob@example.com',
        passwordHash: 'hash-5678',
      );

      expect(outcome, isA<EmailTaken>());
    });

    test('create re-lança exceções do banco com código diferente de 23505', () async {
      final ops = _FakeServerpodAuthDbOperations(
        throwOnInsertEmailAuth: _TestDatabaseQueryException(
          message: 'null value in column violates not-null constraint',
          code: '23502',
          tableName: 'serverpod_email_auth',
        ),
      );
      final repo = ServerpodUserRepository(fakeSession, ops);

      expect(
        () => repo.create(
          name: 'Bob',
          email: 'bob@example.com',
          passwordHash: 'hash-5678',
        ),
        throwsA(isA<DatabaseQueryException>()),
      );
    });

    test('findByEmail devolve CredentialRecord quando o e-mail existe', () async {
      final ops = _FakeServerpodAuthDbOperations(
        existingEmails: {'user@example.com'},
      );
      final repo = ServerpodUserRepository(fakeSession, ops);

      final credential = await repo.findByEmail('user@example.com');

      expect(credential, isNotNull);
      expect(credential!.email, 'user@example.com');
      expect(credential.id, '42');
      expect(credential.passwordHash, contains('argon2id'));
    });

    test('findByEmail devolve null quando o e-mail não existe', () async {
      final ops = _FakeServerpodAuthDbOperations();
      final repo = ServerpodUserRepository(fakeSession, ops);

      final credential = await repo.findByEmail('unknown@example.com');

      expect(credential, isNull);
    });
  });
}

