import 'dart:math';

import 'package:devtasks_api/modules/auth/ports.dart';
import 'package:devtasks_api/modules/auth/session_service.dart';
import 'package:test/test.dart';

/// Repositório fake em memória (chave = tokenHash).
class _FakeSessionRepository implements ISessionRepository {
  final Map<String, SessionRecord> byHash = {};

  @override
  Future<void> save(SessionRecord session) async => byHash[session.tokenHash] = session;

  @override
  Future<SessionRecord?> findByTokenHash(String tokenHash) async => byHash[tokenHash];

  @override
  Future<void> revokeByTokenHash(String tokenHash, DateTime revokedAt) async {
    final current = byHash[tokenHash];
    if (current == null) return;
    byHash[tokenHash] = SessionRecord(
      userId: current.userId,
      tokenHash: current.tokenHash,
      createdAt: current.createdAt,
      expiresAt: current.expiresAt,
      revokedAt: revokedAt,
    );
  }
}

class _FakeCredentialRepository implements ICredentialRepository {
  _FakeCredentialRepository(this.email);

  final String? email;

  @override
  Future<String?> findEmailById(String userId) async => email;

  @override
  Future<CredentialRecord?> findByEmail(String normalizedEmail) async => null;
}

void main() {
  late _FakeSessionRepository repository;
  late DateTime now;

  SessionService service({String? email}) => SessionService(
        repository: repository,
        credentialRepository: email == null ? null : _FakeCredentialRepository(email),
        now: () => now,
        tokenGenerator: TokenGenerator(Random(42)),
      );

  /// Gerador real (`Random.secure()`) — necessário para provar CSPRNG.
  SessionService secureService() => SessionService(
        repository: repository,
        now: () => now,
      );

  setUp(() {
    repository = _FakeSessionRepository();
    now = DateTime.utc(2026, 10, 24, 12);
  });

  group('UC-08.03a — SessionService: emissão (INV-SEC-10/17)', () {
    test('persiste apenas o hash do token, nunca o token puro', () async {
      final issued = await service().createSession(userId: 'u1');

      expect(repository.byHash.keys, hasLength(1));
      expect(repository.byHash.keys.single, TokenGenerator.hash(issued.token));
      expect(repository.byHash.keys.single, isNot(issued.token));
    });

    test('expiração é createdAt + TTL informado', () async {
      final issued = await service().createSession(
        userId: 'u1',
        ttl: const Duration(hours: 2),
      );

      expect(issued.expiresAt, now.add(const Duration(hours: 2)));
      expect(issued.userId, 'u1');
    });

    test('dois tokens emitidos são diferentes (CSPRNG)', () async {
      final first = await secureService().createSession(userId: 'u1');
      final second = await secureService().createSession(userId: 'u1');

      expect(first.token, isNot(second.token));
      expect(repository.byHash, hasLength(2));
    });
  });

  group('UC-08.03a — SessionService: autenticação', () {
    test('token válido devolve o usuário da sessão', () async {
      final issued = await service().createSession(userId: 'u1');

      final user = await service().authenticate(issued.token);

      expect(user, isNotNull);
      expect(user!.id, 'u1');
    });

    test('resolução de e-mail é opcional (porta de credencial)', () async {
      final issued = await service(email: 'bia@ex.com').createSession(userId: 'u1');

      final user = await service(email: 'bia@ex.com').authenticate(issued.token);

      expect(user!.email, 'bia@ex.com');
    });

    test('token vazio é rejeitado sem consultar o repositório', () async {
      expect(await service().authenticate(''), isNull);
    });

    test('token desconhecido é rejeitado (fail-closed)', () async {
      expect(await service().authenticate('nao-existe'), isNull);
    });

    test('sessão expirada é rejeitada', () async {
      final issued = await service().createSession(
        userId: 'u1',
        ttl: const Duration(minutes: 1),
      );
      now = now.add(const Duration(minutes: 2));

      expect(await service().authenticate(issued.token), isNull);
    });

    test('sessão revogada é rejeitada', () async {
      final issued = await service().createSession(userId: 'u1');
      await service().revokeSession(issued.token);

      expect(await service().authenticate(issued.token), isNull);
    });
  });

  group('UC-08.03a — SessionService: revogação', () {
    test('revogar é idempotente e não lança para token ausente', () async {
      final issued = await service().createSession(userId: 'u1');

      await service().revokeSession(issued.token);
      await service().revokeSession(issued.token);
      await service().revokeSession('token-inexistente');

      expect(repository.byHash.values.single.isRevoked, isTrue);
    });

    test('revogar token vazio é no-op', () async {
      await service().revokeSession('');
      expect(repository.byHash, isEmpty);
    });
  });
}
