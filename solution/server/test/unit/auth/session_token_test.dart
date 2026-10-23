import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:devtasks_server/src/generated/protocol.dart';
import 'package:devtasks_server/src/modules/auth/ports.dart';
import 'package:devtasks_server/src/modules/auth/serverpod_session_service.dart';
import 'package:devtasks_server/src/modules/auth/session_guard.dart';
import 'package:devtasks_server/src/modules/auth/sign_in_handler.dart';
import 'package:devtasks_server/src/modules/auth/sign_in_service.dart';
import 'package:test/test.dart';

class InMemorySessionRepository implements SessionRepository {
  final List<SessionRecord> records = [];

  @override
  Future<void> save(SessionRecord session) async {
    records.add(session);
  }

  @override
  Future<SessionRecord?> findByTokenHash(String tokenHash) async {
    try {
      return records.firstWhere((r) => r.tokenHash == tokenHash);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> revokeByTokenHash(String tokenHash, DateTime revokedAt) async {
    for (var i = 0; i < records.length; i++) {
      if (records[i].tokenHash == tokenHash) {
        final existing = records[i];
        records[i] = SessionRecord(
          userId: existing.userId,
          tokenHash: existing.tokenHash,
          createdAt: existing.createdAt,
          expiresAt: existing.expiresAt,
          revokedAt: revokedAt,
        );
      }
    }
  }
}

class _FakeCredentialRepo implements CredentialRepository {
  _FakeCredentialRepo(this.records);
  final Map<String, CredentialRecord> records;

  @override
  Future<CredentialRecord?> findByEmail(String normalizedEmail) async {
    return records[normalizedEmail];
  }

  @override
  Future<String?> findEmailById(String userId) async {
    for (final record in records.values) {
      if (record.id == userId) {
        return record.email;
      }
    }
    return null;
  }
}

class _FakePasswordVerifier implements PasswordVerifier {
  _FakePasswordVerifier({required this.validPassword});
  final String validPassword;

  @override
  Future<bool> verify({required String password, required String passwordHash}) async {
    return password == validPassword;
  }
}

void main() {
  group('UC-01.07 — Emissão e Validação de Sessão com Token Opaco (Gate 3 Fixes)', () {
    late DateTime currentTime;
    DateTime fakeNow() => currentTime;

    setUp(() {
      currentTime = DateTime.utc(2026, 10, 23, 12, 0, 0);
    });

    test('B1 & B2: Emissão no login com oráculo independente sha256 (package:crypto)', () async {
      final sessionRepo = InMemorySessionRepository();
      final credRepo = _FakeCredentialRepo({
        'ana@ex.com': const CredentialRecord(
          id: 'user-123',
          email: 'ana@ex.com',
          passwordHash: 'valid-hash',
        ),
      });
      final sessionService = ServerpodSessionService(
        repository: sessionRepo,
        credentialRepository: credRepo,
        now: fakeNow,
      );

      final verifier = _FakePasswordVerifier(validPassword: 'Password123!');
      final handler = SignInHandler(credRepo, verifier);
      final signInService = SignInService(handler, null, sessionService);

      final result = await signInService.signIn(
        SignInDto(email: 'ana@ex.com', password: 'Password123!'),
      );

      expect(result.success, isTrue);
      expect(result.userId, equals('user-123'));
      expect(result.sessionToken, isNotNull);
      expect(result.sessionToken!.length, greaterThanOrEqualTo(32));
      expect(result.expiresAt, equals(currentTime.add(const Duration(hours: 24))));

      // B2: Oráculo independente via package:crypto
      final rawToken = result.sessionToken!;
      final expectedSha256 = sha256.convert(utf8.encode(rawToken)).toString();

      expect(sessionRepo.records.length, equals(1));
      final saved = sessionRepo.records.first;
      expect(saved.userId, equals('user-123'));
      expect(saved.tokenHash, equals(expectedSha256));
      expect(saved.tokenHash, isNot(equals(rawToken)));
      expect(saved.createdAt, equals(currentTime));
      expect(saved.expiresAt, equals(currentTime.add(const Duration(hours: 24))));
      expect(saved.revokedAt, isNull);
    });

    test('B3: Fail-closed para tokens vazios ou alterados e integridade por digest', () async {
      final sessionRepo = InMemorySessionRepository();
      final sessionService = ServerpodSessionService(
        repository: sessionRepo,
        now: fakeNow,
      );

      final created = await sessionService.createSession(userId: 'user-fail-closed');
      final validToken = created.token;

      // Token vazio -> fail closed
      expect(await sessionService.authenticate(''), isNull);

      // Token com 1 caractere alterado -> fail closed
      final tampered = '${validToken.substring(0, validToken.length - 1)}X';
      expect(await sessionService.authenticate(tampered), isNull);

      // Token com comprimento arbitrário/diferente -> fail closed
      expect(await sessionService.authenticate('token-curto'), isNull);
    });

    test('B5: Resolução de e-mail real na autenticação a partir de CredentialRepository', () async {
      final sessionRepo = InMemorySessionRepository();
      final credRepo = _FakeCredentialRepo({
        'carlos@empresa.com': const CredentialRecord(
          id: 'user-carlos-1',
          email: 'carlos@empresa.com',
          passwordHash: 'hash-carlos',
        ),
      });
      final sessionService = ServerpodSessionService(
        repository: sessionRepo,
        credentialRepository: credRepo,
        now: fakeNow,
      );

      final created = await sessionService.createSession(userId: 'user-carlos-1');
      final authUser = await sessionService.authenticate(created.token);

      expect(authUser, isNotNull);
      expect(authUser!.id, equals('user-carlos-1'));
      expect(authUser.email, equals('carlos@empresa.com'),
          reason: 'B5: E-mail não pode ser string vazia; deve resolver do repositório');
    });

    test('B6: Isolamento entre usuários — revogar sessão de A não afeta sessão de B', () async {
      final sessionRepo = InMemorySessionRepository();
      final sessionService = ServerpodSessionService(
        repository: sessionRepo,
        now: fakeNow,
      );

      final sessionA = await sessionService.createSession(userId: 'user-A');
      final sessionB = await sessionService.createSession(userId: 'user-B');

      expect(sessionA.token, isNot(equals(sessionB.token)));

      // Ambas autenticam
      final authA = await sessionService.authenticate(sessionA.token);
      final authB = await sessionService.authenticate(sessionB.token);
      expect(authA?.id, equals('user-A'));
      expect(authB?.id, equals('user-B'));

      // Revoga apenas sessão de A
      await sessionService.revokeSession(sessionA.token);

      expect(await sessionService.authenticate(sessionA.token), isNull);
      final stillAuthB = await sessionService.authenticate(sessionB.token);
      expect(stillAuthB?.id, equals('user-B'), reason: 'Sessão de B deve continuar ativa');
    });

    test('B6: Validação de expiração temporal (>24h)', () async {
      final sessionRepo = InMemorySessionRepository();
      final sessionService = ServerpodSessionService(
        repository: sessionRepo,
        now: fakeNow,
      );

      final created = await sessionService.createSession(userId: 'user-exp');
      expect(await sessionService.authenticate(created.token), isNotNull);

      // Avança relógio em 24h + 1s
      currentTime = currentTime.add(const Duration(hours: 24, seconds: 1));
      expect(await sessionService.authenticate(created.token), isNull);
    });

    test('SessionGuard com ServerpodSessionService autoriza token válido e bloqueia revogado/expirado', () async {
      final sessionRepo = InMemorySessionRepository();
      final sessionService = ServerpodSessionService(
        repository: sessionRepo,
        now: fakeNow,
      );
      final guard = SessionGuard(sessionService);

      final created = await sessionService.createSession(userId: 'user-guard');
      final outcomeValid = await guard.requireSession(created.token);
      expect(outcomeValid.isAuthorized, isTrue);
      expect(outcomeValid.user?.id, equals('user-guard'));

      await sessionService.revokeSession(created.token);
      final outcomeRevoked = await guard.requireSession(created.token);
      expect(outcomeRevoked.isAuthorized, isFalse);
      expect(outcomeRevoked.code, equals(SessionGuardErrorCode.notAuthenticated));
    });
  });
}
