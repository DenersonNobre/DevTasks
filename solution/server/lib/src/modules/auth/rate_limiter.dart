/// Contrato e modelo de resultado do Rate Limiter (UC-01.04).
sealed class RateLimitOutcome {
  const RateLimitOutcome();

  bool get isAllowed;
}

/// Requisição permitida dentro da cota.
final class RateLimitAllowed extends RateLimitOutcome {
  const RateLimitAllowed({required this.remainingAttempts});

  final int remainingAttempts;

  @override
  bool get isAllowed => true;
}

/// Requisição bloqueada por exceder o teto de tentativas na janela.
final class RateLimited extends RateLimitOutcome {
  const RateLimited({required this.retryAfterSeconds});

  final int retryAfterSeconds;

  @override
  bool get isAllowed => false;
}

/// Porta de controle de taxa de requisições.
abstract interface class RateLimiter {
  RateLimitOutcome check(String key);
}

class _RateLimitEntry {
  _RateLimitEntry({required this.windowStart, required this.count});

  DateTime windowStart;
  int count;
}

/// Implementação em memória com janela fixa e relógio injetado (INV-SEC-12/13).
///
/// Parâmetros canônicos:
/// - [maxAttempts]: 10 tentativas
/// - [window]: 60 segundos
/// - [now]: relógio injetado (DateTime Function()) para testabilidade determinística sem sleep.
///
/// Privacidade e memória (INV-SEC-13):
/// O estado é mantido unicamente em memória volátil de processo, sem persistência
/// em disco nem logs de PII/IP, com evicção periódica de chaves expiradas.
class InMemoryRateLimiter implements RateLimiter {
  InMemoryRateLimiter({
    this.maxAttempts = 10,
    this.window = const Duration(seconds: 60),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final int maxAttempts;
  final Duration window;
  final DateTime Function() _now;

  final Map<String, _RateLimitEntry> _entries = {};
  static const int _maxTrackedKeys = 500;

  @override
  RateLimitOutcome check(String key) {
    final now = _now();

    if (_entries.length > _maxTrackedKeys) {
      _cleanupExpired(now);
    }

    final entry = _entries[key];

    if (entry == null) {
      _entries[key] = _RateLimitEntry(windowStart: now, count: 1);
      return RateLimitAllowed(remainingAttempts: maxAttempts - 1);
    }

    final elapsed = now.difference(entry.windowStart);

    if (elapsed >= window) {
      // Janela expirada: reseta contagem e atualiza o início da janela
      entry.windowStart = now;
      entry.count = 1;
      return RateLimitAllowed(remainingAttempts: maxAttempts - 1);
    }

    if (entry.count >= maxAttempts) {
      final remainingMs = window.inMilliseconds - elapsed.inMilliseconds;
      final retryAfterSeconds = (remainingMs / 1000).ceil();
      return RateLimited(
        retryAfterSeconds: retryAfterSeconds > 0 ? retryAfterSeconds : 1,
      );
    }

    entry.count++;
    final remaining = maxAttempts - entry.count;
    return RateLimitAllowed(remainingAttempts: remaining >= 0 ? remaining : 0);
  }

  void _cleanupExpired(DateTime now) {
    _entries.removeWhere((_, entry) => now.difference(entry.windowStart) >= window);
  }
}
