import 'package:devtasks_server/src/endpoints/auth_endpoint.dart';
import 'package:devtasks_server/src/generated/protocol.dart';
import 'package:devtasks_server/src/modules/auth/ports.dart';
import 'package:devtasks_server/src/modules/auth/request_auth_helper.dart';
import 'package:devtasks_server/src/modules/auth/serverpod_session_service.dart';
import 'package:devtasks_server/src/modules/auth/sign_in_handler.dart';
import 'package:devtasks_server/src/modules/auth/sign_in_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'session_token_test.dart';

class _FakeSession implements Session {
  _FakeSession({this.authHeader});

  final String? authHeader;

  @override
  Request? get request {
    final header = authHeader;
    if (header == null) return null;
    return RequestInternal.create(
      Method.get,
      Uri.parse('http://localhost:8080/'),
      Object(),
      headers: Headers.fromMap({
        'authorization': [header],
      }),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MemoryCredentialRepo implements CredentialRepository {
  _MemoryCredentialRepo(this.records);
  final Map<String, CredentialRecord> records;

  @override
  Future<CredentialRecord?> findByEmail(String normalizedEmail) async =>
      records[normalizedEmail];

  @override
  Future<String?> findEmailById(String userId) async {
    for (final r in records.values) {
      if (r.id == userId) return r.email;
    }
    return null;
  }
}

class _AlwaysValidVerifier implements PasswordVerifier {
  @override
  Future<bool> verify({required String password, required String passwordHash}) async =>
      true;
}

void main() {
  group('UC-01.07 — B1, B4 & B6: Endpoints & RequestAuthHelper (INV-SEC-16)', () {
    test('B1 & B6: RequestAuthHelper extrai Bearer token e ignora lixo ou ausência', () {
      final sessionWithBearer = _FakeSession(authHeader: 'Bearer token-secreto-123');
      expect(
        RequestAuthHelper.extractBearerToken(sessionWithBearer),
        equals('token-secreto-123'),
      );

      final sessionCaseInsensitive = _FakeSession(authHeader: 'bearer token-minusc-456');
      expect(
        RequestAuthHelper.extractBearerToken(sessionCaseInsensitive),
        equals('token-minusc-456'),
      );

      final sessionNoBearer = _FakeSession(authHeader: 'Basic dXNlcjpwYXNz');
      expect(RequestAuthHelper.extractBearerToken(sessionNoBearer), isNull);

      final sessionEmptyHeader = _FakeSession(authHeader: null);
      expect(RequestAuthHelper.extractBearerToken(sessionEmptyHeader), isNull);
    });

    test('B4: AuthEndpoint com wiring injetado emite sessionToken no signIn e signOut revoga via header', () async {
      final sessionRepo = InMemorySessionRepository();
      final credRepo = _MemoryCredentialRepo({
        'dev@devtasks.com': const CredentialRecord(
          id: 'user-dev-99',
          email: 'dev@devtasks.com',
          passwordHash: 'dummy',
        ),
      });
      final sessionService = ServerpodSessionService(
        repository: sessionRepo,
        credentialRepository: credRepo,
      );

      final signInHandler = SignInHandler(credRepo, _AlwaysValidVerifier());
      final signInService = SignInService(signInHandler, null, sessionService);

      final authEndpoint = AuthEndpoint(
        null,
        signInService,
        null,
        sessionService,
      );

      final session = _FakeSession(authHeader: null);

      // 1. signIn emite token opaco não-vazio
      final loginResult = await authEndpoint.signIn(
        session,
        SignInDto(email: 'dev@devtasks.com', password: 'QualquerSenha!123'),
      );

      expect(loginResult.success, isTrue);
      expect(loginResult.userId, equals('user-dev-99'));
      expect(loginResult.sessionToken, isNotNull);
      final token = loginResult.sessionToken!;

      // 2. Token é autenticável e resolve o e-mail real
      final authUser = await sessionService.authenticate(token);
      expect(authUser?.id, equals('user-dev-99'));
      expect(authUser?.email, equals('dev@devtasks.com'));

      // 3. signOut via Header Authorization: Bearer revoga o token
      final sessionSignOut = _FakeSession(authHeader: 'Bearer $token');
      final signOutResult = await authEndpoint.signOut(sessionSignOut);
      expect(signOutResult.success, isTrue);

      // 4. Token revogado não autentica mais
      expect(await sessionService.authenticate(token), isNull);

      // 5. Segundo signOut é idempotente
      final secondSignOut = await authEndpoint.signOut(sessionSignOut);
      expect(secondSignOut.success, isTrue);
    });
  });
}
