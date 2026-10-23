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

/// Implementação em memória com janela fixa e relógio injetado (INV-SEC-12/13).
class InMemoryRateLimiter implements RateLimiter {
  InMemoryRateLimiter({
    this.maxAttempts = 10,
    this.window = const Duration(seconds: 60),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final int maxAttempts;
  final Duration window;
  final DateTime Function() _now;

  @override
  RateLimitOutcome check(String key) {
    // STUB inicial para comprovar o estado Red antes da implementação
    return const RateLimitAllowed(remainingAttempts: 10);
  }
}

