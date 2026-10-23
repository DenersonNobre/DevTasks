import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import 'package:devtasks_server/src/generated/protocol.dart';
import 'package:devtasks_server/src/modules/auth/ports.dart';
import 'package:devtasks_server/src/modules/auth/session_guard.dart';
import 'package:devtasks_server/src/modules/auth/serverpod_session_service.dart';
import 'package:devtasks_server/src/modules/auth/sign_in_service.dart';
import 'package:devtasks_server/src/modules/auth/sign_in_handler.dart';

class _FakeCredentialRepo implements CredentialRepository {
  _FakeCredentialRepo(this.records);
  final Map<String, CredentialRecord> records;

  @override
  Future<CredentialRecord?> findByEmail(String normalizedEmail) async {
    return records[normalizedEmail];
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
  group('UC-01.07 — Emissão e Validação de Sessão com Token Opaco', () {
    late DateTime currentTime;
    DateTime fakeNow() => currentTime;

    setUp(() {
      currentTime = DateTime.utc(2026, 10, 23, 12, 0, 0);
    });

    test('Red: Emissão de token no login bem-sucedido com hash SHA-256 no banco e TTL de 24h', () async {
      final sessionStore = InMemorySessionStore();
      final sessionService = ServerpodSessionService(
        store: sessionStore,
        now: fakeNow,
      );

      final credRepo = _FakeCredentialRepo({
        'ana@ex.com': const CredentialRecord(
          id: 'user-123',
          email: 'ana@ex.com',
          passwordHash: 'valid-hash',
        ),
      });
      final verifier = _FakePasswordVerifier(validPassword: 'Password123!');
      final handler = SignInHandler(credRepo, verifier);

      final signInService = SignInService(
        handler,
        null, // sem rate limiter no unit puro de emissão
        sessionService: sessionService,
      );

      final result = await signInService.signIn(
        SignInDto(email: 'ana@ex.com', password: 'Password123!'),
      );

      expect(result.success, isTrue);
      expect(result.userId, equals('user-123'));
      expect(result.sessionToken, isNotNull);
      expect(result.sessionToken!.length, greaterThanOrEqualTo(32));
      expect(result.expiresAt, equals(currentTime.add(const Duration(hours: 24))));

      // Prova de armazenamento: somente o hash SHA-256 está no store
      final rawToken = result.sessionToken!;
      final expectedHash = sha256.convert(utf8.encode(rawToken)).toString();
      
      expect(sessionStore.savedSessions.length, equals(1));
      final saved = sessionStore.savedSessions.first;
      expect(saved.userId, equals('user-123'));
      expect(saved.tokenHash, equals(expectedHash));
      expect(saved.tokenHash, isNot(equals(rawToken)));
      expect(saved.createdAt, equals(currentTime));
      expect(saved.expiresAt, equals(currentTime.add(const Duration(hours: 24))));
      expect(saved.revokedAt, isNull);
    });

    test('Red: Validação aceita token válido e rejeita token expirado (>24h)', () async {
      final sessionStore = InMemorySessionStore();
      final sessionService = ServerpodSessionService(
        store: sessionStore,
        now: fakeNow,
      );

      final created = await sessionService.createSession(userId: 'user-456');
      final token = created.token;

      // Token válido dentro do TTL
      final authUser = await sessionService.authenticate(token);
      expect(authUser, isNotNull);
      expect(authUser!.id, equals('user-456'));

      // Avança o relógio para 24h + 1s (expirado)
      currentTime = currentTime.add(const Duration(hours: 24, seconds: 1));

      final expiredUser = await sessionService.authenticate(token);
      expect(expiredUser, isNull, reason: 'Token deve ser rejeitado após o TTL de 24h');
    });

    test('Red: Revogação no signOut torna token inválido e é idempotente', () async {
      final sessionStore = InMemorySessionStore();
      final sessionService = ServerpodSessionService(
        store: sessionStore,
        now: fakeNow,
      );

      final created = await sessionService.createSession(userId: 'user-789');
      final token = created.token;

      // 1º signOut: revoga sessão
      final signOutResult1 = await sessionService.signOut(token);
      expect(signOutResult1.success, isTrue);

      // Autenticação após revogação devolve null
      final authUser = await sessionService.authenticate(token);
      expect(authUser, isNull, reason: 'Token revogado não pode autenticar');

      // 2º signOut (mesmo token): idempotente, responde success sem vazar estado
      final signOutResult2 = await sessionService.signOut(token);
      expect(signOutResult2.success, isTrue);

      // signOut de token inexistente: também responde success: true idempotente
      final signOutResultRandom = await sessionService.signOut('token-totalmente-inexistente');
      expect(signOutResultRandom.success, isTrue);
    });

    test('Red: SessionGuard com ServerpodSessionService autoriza token válido e bloqueia revogado/expirado', () async {
      final sessionStore = InMemorySessionStore();
      final sessionService = ServerpodSessionService(
        store: sessionStore,
        now: fakeNow,
      );

      final guard = SessionGuard(sessionService);

      final created = await sessionService.createSession(userId: 'user-abc');
      final token = created.token;

      final guardOutcomeValid = await guard.requireSession(token);
      expect(guardOutcomeValid.isAuthorized, isTrue);
      expect(guardOutcomeValid.user?.id, equals('user-abc'));

      // Revoga
      await sessionService.signOut(token);

      final guardOutcomeRevoked = await guard.requireSession(token);
      expect(guardOutcomeRevoked.isAuthorized, isFalse);
      expect(guardOutcomeRevoked.code, equals(SessionGuardErrorCode.notAuthenticated));
    });
  });
}
