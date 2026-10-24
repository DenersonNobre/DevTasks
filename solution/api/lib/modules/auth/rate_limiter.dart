import 'dart:collection';

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

/// Implementação em memória com janela fixa, evicção LRU O(1) e relógio injetado (INV-SEC-02/13/14).
///
/// Parâmetros canônicos:
/// - [maxAttempts]: 10 tentativas por janela.
/// - [window]: 60 segundos.
/// - [maxTrackedKeys]: teto duro de memória (default 500 chaves).
/// - [now]: relógio injetado obrigatório (DateTime Function()) sem dependência implícita de relógio de sistema.
///
/// Política de contenção de memória (INV-SEC-14 / Bloqueante 1):
/// Utiliza [LinkedHashMap] como cache LRU. Ao atingir [maxTrackedKeys], desalija a chave
/// menos recentemente usada (oldest key da cabeça do mapa) em tempo O(1), prevenindo
/// exaustão de heap (DoS via criação massiva de chaves) e sem qualquer varredura O(N) no caminho quente.
class InMemoryRateLimiter implements RateLimiter {
  InMemoryRateLimiter({
    required this.now,
    this.maxAttempts = 10,
    this.window = const Duration(seconds: 60),
    this.maxTrackedKeys = 500,
  });

  final int maxAttempts;
  final Duration window;
  final int maxTrackedKeys;
  final DateTime Function() now;

  final LinkedHashMap<String, _RateLimitEntry> _entries =
      LinkedHashMap<String, _RateLimitEntry>();

  /// Quantidade atual de chaves rastreadas em memória (inspeção de governança / testes).
  int get trackedKeysCount => _entries.length;

  @override
  RateLimitOutcome check(String key) {
    final currentTime = now();

    final existing = _entries.remove(key);

    if (existing != null) {
      final elapsed = currentTime.difference(existing.windowStart);

      if (elapsed >= window) {
        // Janela expirada: reinicia contagem para a chave e coloca no fim (MRU)
        existing.windowStart = currentTime;
        existing.count = 1;
        _entries[key] = existing;
        return RateLimitAllowed(remainingAttempts: maxAttempts - 1);
      }

      // Reinsere a entrada existente no fim para renovar recência (MRU)
      _entries[key] = existing;

      if (existing.count >= maxAttempts) {
        final remainingMs = window.inMilliseconds - elapsed.inMilliseconds;
        final retryAfterSeconds = (remainingMs / 1000).ceil();
        return RateLimited(
          retryAfterSeconds: retryAfterSeconds > 0 ? retryAfterSeconds : 1,
        );
      }

      existing.count++;
      final remaining = maxAttempts - existing.count;
      return RateLimitAllowed(remainingAttempts: remaining >= 0 ? remaining : 0);
    }

    // Chave nova: se atingiu o teto duro, desalija a menos recentemente usada (LRU head) em O(1)
    if (_entries.length >= maxTrackedKeys) {
      final oldestKey = _entries.keys.first;
      _entries.remove(oldestKey);
    }

    _entries[key] = _RateLimitEntry(windowStart: currentTime, count: 1);
    return RateLimitAllowed(remainingAttempts: maxAttempts - 1);
  }
}