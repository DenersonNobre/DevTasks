import 'package:devtasks_api/modules/auth/rate_limiter.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryRateLimiter — Janela Fixa & LRU (INV-SEC-02/13/14)', () {
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
        expect(
          outcome.isAllowed,
          isTrue,
          reason: 'Tentativa $i de 10 deve ser permitida',
        );
        expect(outcome, isA<RateLimitAllowed>());
        final allowed = outcome as RateLimitAllowed;
        expect(allowed.remainingAttempts, 10 - i);
      }

      final blockedOutcome = limiter.check(key);
      expect(
        blockedOutcome.isAllowed,
        isFalse,
        reason: '11ª tentativa deve ser bloqueada por rate limit',
      );
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

      currentTime = currentTime.add(const Duration(seconds: 61));

      final outcomeAfterWindow = limiter.check(key);
      expect(
        outcomeAfterWindow.isAllowed,
        isTrue,
        reason: 'Após 60s, a cota deve ser reiniciada',
      );
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
      expect(
        limiter.check(ip2).isAllowed,
        isTrue,
        reason: 'IP diferente não pode ser afetado pelo esgotamento da cota de outro',
      );
    });

    test('B1: teto duro de memória com evicção LRU O(1) mantém entradas <= maxTrackedKeys', () {
      final currentTime = DateTime.utc(2026, 10, 23, 12, 0, 0);
      const cap = 3;

      final limiter = InMemoryRateLimiter(
        maxAttempts: 10,
        window: const Duration(seconds: 60),
        maxTrackedKeys: cap,
        now: () => currentTime,
      );

      limiter.check('ip-1');
      limiter.check('ip-2');
      limiter.check('ip-3');

      expect(limiter.trackedKeysCount, cap);

      limiter.check('ip-1');
      limiter.check('ip-4');

      expect(
        limiter.trackedKeysCount,
        cap,
        reason: 'O número de chaves em memória NUNCA pode ultrapassar o cap',
      );

      final outcomeIp2 = limiter.check('ip-2') as RateLimitAllowed;
      expect(
        outcomeIp2.remainingAttempts,
        9,
        reason: 'ip-2 foi evictado pelo LRU e recomeça como nova chave',
      );

      expect(limiter.trackedKeysCount, cap);
    });
  });
}
