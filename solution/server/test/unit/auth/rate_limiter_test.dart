import 'package:devtasks_server/src/generated/protocol.dart';
import 'package:devtasks_server/src/modules/auth/ports.dart';
import 'package:devtasks_server/src/modules/auth/rate_limiter.dart';
import 'package:devtasks_server/src/modules/auth/sign_in_handler.dart';
import 'package:devtasks_server/src/modules/auth/sign_in_service.dart';
import 'package:devtasks_server/src/modules/auth/sign_up_handler.dart';
import 'package:devtasks_server/src/modules/auth/sign_up_service.dart';
import 'package:test/test.dart';

class _FakeCredentials implements CredentialRepository {
  _FakeCredentials({Map<String, String>? hashes}) : _hashes = hashes ?? {};
  final Map<String, String> _hashes;

  @override
  Future<CredentialRecord?> findByEmail(String normalizedEmail) async {
    final hash = _hashes[normalizedEmail];
    if (hash == null) return null;
    return CredentialRecord(
      id: 'user-1',
      email: normalizedEmail,
      passwordHash: hash,
    );
  }
}

class _CountingPasswordVerifier implements PasswordVerifier {
  int verifyCalls = 0;

  @override
  Future<bool> verify({
    required String password,
    required String passwordHash,
  }) async {
    verifyCalls++;
    return password == 'F0rtress!Pass2026' && passwordHash == 'valid-hash';
  }
}

class _CountingPasswordHasher implements PasswordHasher {
  int hashCalls = 0;

  @override
  Future<String> hash(String password) async {
    hashCalls++;
    return 'fake-hash::$password';
  }
}

class _FakeUserRepository implements UserRepository {
  @override
  Future<bool> existsByEmail(String normalizedEmail) async => false;

  @override
  Future<CreateUserOutcome> create({
    required String name,
    required String email,
    required String passwordHash,
  }) async {
    return UserCreated(
      RegisteredUser(
        id: 'user-new',
        name: name,
        email: email,
        emailVerified: false,
      ),
    );
  }
}

void main() {
  group('InMemoryRateLimiter — Gherkin F1.4 & Janela Fixa (INV-SEC-12/13)', () {
    test('10 tentativas consecutivas são permitidas; a 11ª tentativa é bloqueada', () {
      var currentTime = DateTime.utc(2026, 10, 23, 12, 0, 0);
      final limiter = InMemoryRateLimiter(
        maxAttempts: 10,
        window: const Duration(seconds: 60),
        now: () => currentTime,
      );

      const key = 'signin:192.168.1.100';

      for (var i = 1; i <= 10; i++) {
        final outcome = limiter.check(key);
        expect(outcome.isAllowed, isTrue,
            reason: 'Tentativa $i de 10 deve ser permitida');
        expect(outcome, isA<RateLimitAllowed>());
        final allowed = outcome as RateLimitAllowed;
        expect(allowed.remainingAttempts, 10 - i);
      }

      // 11ª tentativa no mesmo minuto deve ser bloqueada
      final blockedOutcome = limiter.check(key);
      expect(blockedOutcome.isAllowed, isFalse,
          reason: '11ª tentativa deve ser bloqueada por rate limit');
      expect(blockedOutcome, isA<RateLimited>());
      final rateLimited = blockedOutcome as RateLimited;
      expect(rateLimited.retryAfterSeconds, greaterThan(0));
    });

    test('após expirar a janela de 60s, a cota é reiniciada para novas tentativas', () {
      var currentTime = DateTime.utc(2026, 10, 23, 12, 0, 0);
      final limiter = InMemoryRateLimiter(
        maxAttempts: 10,
        window: const Duration(seconds: 60),
        now: () => currentTime,
      );

      const key = 'signin:192.168.1.101';

      for (var i = 0; i < 10; i++) {
        limiter.check(key);
      }
      expect(limiter.check(key).isAllowed, isFalse);

      // Avança o relógio injetado em 61 segundos (sem sleep)
      currentTime = currentTime.add(const Duration(seconds: 61));

      final outcomeAfterWindow = limiter.check(key);
      expect(outcomeAfterWindow.isAllowed, isTrue,
          reason: 'Após 60s, a cota deve ser reiniciada');
    });

    test('IPs distintos possuem cotas estritamente independentes', () {
      var currentTime = DateTime.utc(2026, 10, 23, 12, 0, 0);
      final limiter = InMemoryRateLimiter(
        maxAttempts: 10,
        window: const Duration(seconds: 60),
        now: () => currentTime,
      );

      const ip1 = 'signin:10.0.0.1';
      const ip2 = 'signin:10.0.0.2';

      for (var i = 0; i < 10; i++) {
        limiter.check(ip1);
      }

      expect(limiter.check(ip1).isAllowed, isFalse);
      expect(limiter.check(ip2).isAllowed, isTrue,
          reason: 'IP diferente não pode ser afetado pelo esgotamento da cota de outro');
    });
  });

  group('Rate Limit no SignInService — Prova de sem custo de senha (INV-SEC-12)', () {
    test('11ª tentativa de login bloqueada devolve ERR_RATE_LIMITED e NÃO chama o PasswordVerifier',
        () async {
      var currentTime = DateTime.utc(2026, 10, 23, 12, 0, 0);
      final limiter = InMemoryRateLimiter(
        maxAttempts: 10,
        window: const Duration(seconds: 60),
        now: () => currentTime,
      );

      final verifier = _CountingPasswordVerifier();
      final handler = SignInHandler(
        _FakeCredentials(hashes: {'user@example.com': 'valid-hash'}),
        verifier,
      );

      final service = SignInService(handler, limiter);

      const clientIp = '172.16.0.5';

      // 10 tentativas com senha incorreta
      for (var i = 1; i <= 10; i++) {
        final result = await service.signIn(
          SignInDto(email: 'user@example.com', password: 'WrongPassword123!'),
          clientIp: clientIp,
        );
        expect(result.success, isFalse);
        expect(result.errorCode, 'ERR_INVALID_CREDENTIALS');
      }

      // Verifier foi chamado 10 vezes
      expect(verifier.verifyCalls, 10);

      // 11ª tentativa pelo mesmo IP deve ser barrada pelo rate limiter
      final blockedResult = await service.signIn(
        SignInDto(email: 'user@example.com', password: 'WrongPassword123!'),
        clientIp: clientIp,
      );

      expect(blockedResult.success, isFalse);
      expect(blockedResult.errorCode, 'ERR_RATE_LIMITED');
      expect(
        blockedResult.message,
        'Muitas tentativas de autenticação. Tente novamente mais tarde.',
      );

      // Prova cabal: nenhuma computação de senha ocorreu na 11ª tentativa
      expect(
        verifier.verifyCalls,
        10,
        reason: 'O PasswordVerifier NÃO pode ser invocado na tentativa rate-limited (INV-SEC-12)',
      );
    });
  });

  group('Rate Limit no SignUpService — Prova de sem custo de senha (INV-SEC-12)', () {
    test('11ª tentativa de cadastro bloqueada devolve ERR_RATE_LIMITED e NÃO chama o PasswordHasher',
        () async {
      var currentTime = DateTime.utc(2026, 10, 23, 12, 0, 0);
      final limiter = InMemoryRateLimiter(
        maxAttempts: 10,
        window: const Duration(seconds: 60),
        now: () => currentTime,
      );

      final hasher = _CountingPasswordHasher();
      final handler = SignUpHandler(_FakeUserRepository(), hasher);
      final service = SignUpService(handler, limiter);

      const clientIp = '192.168.10.50';

      // 10 cadastros válidos
      for (var i = 1; i <= 10; i++) {
        final result = await service.signUp(
          SignUpDto(
            name: 'User $i',
            email: 'user$i@example.com',
            password: 'F0rtress!Pass2026',
          ),
          clientIp: clientIp,
        );
        expect(result.success, isTrue);
      }

      expect(hasher.hashCalls, 10);

      // 11ª tentativa pelo mesmo IP é bloqueada pelo rate limiter
      final blockedResult = await service.signUp(
        SignUpDto(
          name: 'User 11',
          email: 'user11@example.com',
          password: 'F0rtress!Pass2026',
        ),
        clientIp: clientIp,
      );

      expect(blockedResult.success, isFalse);
      expect(blockedResult.errorCode, 'ERR_RATE_LIMITED');
      expect(
        blockedResult.message,
        'Muitas tentativas de cadastro. Tente novamente mais tarde.',
      );

      // Prova cabal: Hasher NÃO chamado na 11ª tentativa
      expect(
        hasher.hashCalls,
        10,
        reason: 'O PasswordHasher NÃO pode ser invocado na tentativa rate-limited (INV-SEC-12)',
      );
    });

    test('dados inválidos na fronteira falham com ERR_VALIDATION sem invocar o PasswordHasher',
        () async {
      final hasher = _CountingPasswordHasher();
      final handler = SignUpHandler(_FakeUserRepository(), hasher);
      final service = SignUpService(handler);

      // 1. E-mail malformado
      final badEmailResult = await service.signUp(
        SignUpDto(
          name: 'User Bad',
          email: 'not-an-email',
          password: 'F0rtress!Pass2026',
        ),
      );
      expect(badEmailResult.success, isFalse);
      expect(badEmailResult.errorCode, 'ERR_VALIDATION');
      expect(badEmailResult.field, 'email');
      expect(hasher.hashCalls, 0);

      // 2. Senha fora da política
      final badPassResult = await service.signUp(
        SignUpDto(
          name: 'User Bad Pass',
          email: 'user@example.com',
          password: 'short',
        ),
      );
      expect(badPassResult.success, isFalse);
      expect(badPassResult.errorCode, 'ERR_VALIDATION');
      expect(badPassResult.field, 'password');
      expect(hasher.hashCalls, 0);
    });
  });
}
