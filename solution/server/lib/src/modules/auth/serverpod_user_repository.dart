import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';

import 'ports.dart';

/// Operações de persistência com o ORM do Serverpod (abstração para testabilidade pura).
abstract interface class ServerpodAuthDbOperations {
  Future<bool> emailAuthExists(Session session, String normalizedEmail);
  Future<EmailAuth?> findEmailAuth(Session session, String normalizedEmail);
  Future<UserInfo> insertUserInfo(Session session, UserInfo userInfo);
  Future<EmailAuth> insertEmailAuth(Session session, EmailAuth emailAuth);
}

class _DefaultServerpodAuthDbOperations implements ServerpodAuthDbOperations {
  const _DefaultServerpodAuthDbOperations();

  @override
  Future<bool> emailAuthExists(Session session, String normalizedEmail) async {
    final count = await EmailAuth.db.count(
      session,
      where: (t) => t.email.equals(normalizedEmail),
    );
    return count > 0;
  }

  @override
  Future<EmailAuth?> findEmailAuth(
    Session session,
    String normalizedEmail,
  ) async {
    return EmailAuth.db.findFirstRow(
      session,
      where: (t) => t.email.equals(normalizedEmail),
    );
  }

  @override
  Future<UserInfo> insertUserInfo(Session session, UserInfo userInfo) async {
    return UserInfo.db.insertRow(session, userInfo);
  }

  @override
  Future<EmailAuth> insertEmailAuth(
    Session session,
    EmailAuth emailAuth,
  ) async {
    return EmailAuth.db.insertRow(session, emailAuth);
  }
}

/// Adaptador de infraestrutura que conecta os contratos de domínio [UserRepository]
/// e [CredentialRepository] ao ORM Serverpod e PostgreSQL.
///
/// Modelos utilizados (legado `serverpod_auth_server` 3.4.x):
/// - [UserInfo]: Tabela `serverpod_user_info` (perfil público e metadados).
///   `emailVerified` é semanticamente `false` no cadastro inicial.
/// - [EmailAuth]: Tabela `serverpod_email_auth` (credenciais com índice UNIQUE em `email`).
///
/// Mitigação do TOCTOU:
/// Captura deterministicamente o SQLSTATE `23505` (`unique_violation`) do PostgreSQL
/// via [DatabaseQueryException.code] e converte em [EmailTaken] sem lançar exceções.
class ServerpodUserRepository implements UserRepository, CredentialRepository {
  const ServerpodUserRepository(
    this.session, [
    ServerpodAuthDbOperations? operations,
  ]) : _ops = operations ?? const _DefaultServerpodAuthDbOperations();

  /// Código SQLSTATE do PostgreSQL para violação de unicidade (`unique_violation`).
  static const String pgUniqueViolationSqlState = '23505';

  final Session session;
  final ServerpodAuthDbOperations _ops;

  @override
  Future<bool> existsByEmail(String normalizedEmail) =>
      _ops.emailAuthExists(session, normalizedEmail);

  @override
  Future<CreateUserOutcome> create({
    required String name,
    required String email,
    required String passwordHash,
  }) async {
    try {
      // 1. Cria UserInfo com e-mail normalizado e emailVerified = false.
      final userInfo = UserInfo(
        userIdentifier: email,
        userName: name,
        email: email,
        created: DateTime.now().toUtc(),
        scopeNames: const [],
        blocked: false,
      );
      final savedUserInfo = await _ops.insertUserInfo(session, userInfo);

      final userId = savedUserInfo.id;
      if (userId == null) {
        throw StateError('Falha de integridade: UserInfo inserido sem ID.');
      }

      // 2. Cria EmailAuth com vínculo no userId gerado e o hash seguro.
      final emailAuth = EmailAuth(
        userId: userId,
        email: email,
        hash: passwordHash,
      );
      await _ops.insertEmailAuth(session, emailAuth);

      return UserCreated(
        RegisteredUser(
          id: userId.toString(),
          name: savedUserInfo.userName ?? name,
          email: email,
          emailVerified: false,
        ),
      );
    } catch (e) {
      if (_isUniqueConstraintViolation(e)) {
        return const EmailTaken();
      }
      rethrow;
    }
  }

  @override
  Future<CredentialRecord?> findByEmail(String normalizedEmail) async {
    final auth = await _ops.findEmailAuth(session, normalizedEmail);
    if (auth == null) {
      return null;
    }
    return CredentialRecord(
      id: auth.userId.toString(),
      email: auth.email,
      passwordHash: auth.hash,
    );
  }

  static bool _isUniqueConstraintViolation(Object error) {
    if (error is DatabaseQueryException &&
        error.code == pgUniqueViolationSqlState) {
      return true;
    }
    try {
      final dynamic dyn = error;
      if (dyn.code == pgUniqueViolationSqlState) {
        return true;
      }
    } catch (_) {}
    return false;
  }
}

