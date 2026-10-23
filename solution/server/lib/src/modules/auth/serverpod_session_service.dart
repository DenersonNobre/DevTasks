import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/digests/sha256.dart';
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'ports.dart';

/// Abstração para persistência de sessões (`devtasks_session`).
abstract interface class SessionStore {
  Future<void> save(DevtasksSession session);
  Future<DevtasksSession?> findByTokenHash(String tokenHash);
  Future<void> revokeByTokenHash(String tokenHash, DateTime revokedAt);
}

/// Implementação em memória de [SessionStore] para testes puros e isolamento sem DB.
class InMemorySessionStore implements SessionStore {
  final List<DevtasksSession> savedSessions = [];

  @override
  Future<void> save(DevtasksSession session) async {
    savedSessions.add(session);
  }

  @override
  Future<DevtasksSession?> findByTokenHash(String tokenHash) async {
    try {
      return savedSessions.firstWhere((s) => s.tokenHash == tokenHash);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> revokeByTokenHash(String tokenHash, DateTime revokedAt) async {
    for (var i = 0; i < savedSessions.length; i++) {
      if (savedSessions[i].tokenHash == tokenHash) {
        final existing = savedSessions[i];
        savedSessions[i] = existing.copyWith(revokedAt: revokedAt);
      }
    }
  }
}

/// Adaptador Serverpod para [SessionStore] que interage com a tabela `devtasks_session`.
class ServerpodSessionStore implements SessionStore {
  const ServerpodSessionStore(this._session);

  final Session _session;

  @override
  Future<void> save(DevtasksSession session) async {
    await DevtasksSession.db.insertRow(_session, session);
  }

  @override
  Future<DevtasksSession?> findByTokenHash(String tokenHash) async {
    return DevtasksSession.db.findFirstRow(
      _session,
      where: (t) => t.tokenHash.equals(tokenHash),
    );
  }

  @override
  Future<void> revokeByTokenHash(String tokenHash, DateTime revokedAt) async {
    final existing = await findByTokenHash(tokenHash);
    if (existing != null) {
      await DevtasksSession.db.updateRow(
        _session,
        existing.copyWith(revokedAt: revokedAt),
        columns: (t) => [t.revokedAt],
      );
    }
  }
}

/// Par de credencial emitido (token opaco puro retornado ao cliente + metadados).
class IssuedSession {
  const IssuedSession({
    required this.token,
    required this.expiresAt,
    required this.userId,
  });

  /// Token opaco devolvido uma única vez ao cliente (INV-SEC-05).
  final String token;
  final DateTime expiresAt;
  final String userId;
}

/// Serviço de emissão, validação e revogação de tokens de sessão opacos.
class ServerpodSessionService implements SessionAuthenticator {
  ServerpodSessionService({
    required this.store,
    DateTime Function()? now,
    Random? random,
  })  : _now = now ?? DateTime.now,
        _random = random ?? Random.secure();

  final SessionStore store;
  final DateTime Function() _now;
  final Random _random;

  /// TTL padrão de 24 horas para tokens de sessão.
  static const Duration defaultTtl = Duration(hours: 24);

  /// Gera um token opaco criptograficamente seguro com 32 bytes (256 bits).
  String _generateSecureToken() {
    final values = List<int>.generate(32, (_) => _random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Calcula o hash SHA-256 canônico em hexadecimal do token opaco via PointyCastle.
  static String hashToken(String token) {
    final digest = SHA256Digest();
    final bytes = utf8.encode(token);
    final hashBytes = digest.process(Uint8List.fromList(bytes));
    return hashBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Compara dois hashes em tempo constante para mitigar side-channel de timing (Gate 2.5).
  static bool constantTimeCompare(String a, String b) {
    if (a.length != b.length) {
      return false;
    }
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Cria e persiste uma nova sessão com token opaco.
  Future<IssuedSession> createSession({
    required String userId,
    Duration ttl = defaultTtl,
  }) async {
    final rawToken = _generateSecureToken();
    final tokenHash = hashToken(rawToken);
    final createdAt = _now();
    final expiresAt = createdAt.add(ttl);

    final sessionRecord = DevtasksSession(
      userId: userId,
      tokenHash: tokenHash,
      createdAt: createdAt,
      expiresAt: expiresAt,
      revokedAt: null,
    );

    await store.save(sessionRecord);

    return IssuedSession(
      token: rawToken,
      expiresAt: expiresAt,
      userId: userId,
    );
  }

  @override
  Future<AuthenticatedUser?> authenticate(String token) async {
    final tokenHash = hashToken(token);
    final sessionRecord = await store.findByTokenHash(tokenHash);

    if (sessionRecord == null) {
      return null;
    }

    // Validação de tempo constante do hash
    if (!constantTimeCompare(sessionRecord.tokenHash, tokenHash)) {
      return null;
    }

    // Rejeita sessão revogada
    if (sessionRecord.revokedAt != null) {
      return null;
    }

    // Rejeita sessão expirada (TTL)
    final now = _now();
    if (now.isAfter(sessionRecord.expiresAt)) {
      return null;
    }

    return AuthenticatedUser(
      id: sessionRecord.userId,
      email: '', // O email pode ser carregado sob demanda se necessário
    );
  }

  /// Revoga o token atual (idempotente: token já revogado ou ausente retorna sucesso).
  Future<SignOutResultDto> signOut(String token) async {
    final tokenHash = hashToken(token);
    final now = _now();
    await store.revokeByTokenHash(tokenHash, now);
    return SignOutResultDto(success: true);
  }
}
