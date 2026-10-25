import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/digests/sha256.dart';

import 'ports.dart';

/// Par de credencial emitido (token opaco puro retornado ao cliente + metadados).
class IssuedSession {
  const IssuedSession({
    required this.token,
    required this.expiresAt,
    required this.userId,
  });

  /// Token opaco devolvido uma única vez ao cliente (INV-SEC-10).
  final String token;
  final DateTime expiresAt;
  final String userId;
}

/// Gerador criptográfico seguro de tokens opacos (INV-SEC-10).
class TokenGenerator {
  const TokenGenerator([Random? random]) : _random = random;

  final Random? _random;

  /// Gera um token opaco criptograficamente seguro com 32 bytes (256 bits).
  String generate() {
    final rng = _random ?? Random.secure();
    final values = List<int>.generate(32, (_) => rng.nextInt(256));
    return base64Url.encode(values);
  }

  /// Calcula o hash SHA-256 canônico em hexadecimal do token opaco via PointyCastle.
  static String hash(String token) {
    final digest = SHA256Digest();
    final bytes = utf8.encode(token);
    final hashBytes = digest.process(Uint8List.fromList(bytes));
    return hashBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

/// Serviço de emissão, validação e revogação de tokens de sessão opacos.
///
/// Aplica Object Calisthenics:
/// - 1 nível de indentação por método;
/// - Early-return para evitar cláusulas 'else' ou aninhamentos;
/// - SRP: delega geração criptográfica para [TokenGenerator] e persistência para [SessionRepository].
///
/// Segurança (Gate 2.5):
/// - A integridade e segurança temporal repousam no índice UNIQUE em `tokenHash` (256 bits SHA-256, INV-SEC-17);
/// - Rejeição estrita fail-closed para tokens com formato inválido, expirados ou revogados.
class SessionService implements ISessionAuthenticator {
  SessionService({
    required this.repository,
    this.credentialRepository,
    Duration? defaultTtl,
    DateTime Function()? now,
    TokenGenerator? tokenGenerator,
  })  : sessionTtl = defaultTtl ?? defaultSessionTtl,
        _now = now ?? DateTime.now,
        _generator = tokenGenerator ?? const TokenGenerator();

  final ISessionRepository repository;
  final ICredentialRepository? credentialRepository;
  final Duration sessionTtl;
  final DateTime Function() _now;
  final TokenGenerator _generator;

  /// TTL padrão de 24 horas para tokens de sessão (INV-SEC-10).
  static const Duration defaultSessionTtl = Duration(hours: 24);

  /// Cria e persiste uma nova sessão com token opaco.
  Future<IssuedSession> createSession({
    required String userId,
    Duration? ttl,
  }) async {
    final effectiveTtl = ttl ?? sessionTtl;
    final rawToken = _generator.generate();
    final tokenHash = TokenGenerator.hash(rawToken);
    final createdAt = _now();
    final expiresAt = createdAt.add(effectiveTtl);

    final record = SessionRecord(
      userId: userId,
      tokenHash: tokenHash,
      createdAt: createdAt,
      expiresAt: expiresAt,
      revokedAt: null,
    );

    await repository.save(record);

    return IssuedSession(
      token: rawToken,
      expiresAt: expiresAt,
      userId: userId,
    );
  }

  @override
  Future<AuthenticatedUser?> authenticate(String token) async {
    if (token.isEmpty) {
      return null;
    }

    final tokenHash = TokenGenerator.hash(token);
    final sessionRecord = await repository.findByTokenHash(tokenHash);
    if (sessionRecord == null) {
      return null;
    }

    if (sessionRecord.isRevoked) {
      return null;
    }

    final now = _now();
    if (sessionRecord.isExpired(now)) {
      return null;
    }

    String? email;
    final credRepo = credentialRepository;
    if (credRepo != null) {
      email = await credRepo.findEmailById(sessionRecord.userId);
    }

    return AuthenticatedUser(
      id: sessionRecord.userId,
      email: email ?? '',
    );
  }

  /// Revoga o token atual (idempotente: token já revogado ou ausente retorna sucesso).
  Future<void> revokeSession(String token) async {
    if (token.isEmpty) {
      return;
    }
    final tokenHash = TokenGenerator.hash(token);
    final now = _now();
    await repository.revokeByTokenHash(tokenHash, now);
  }
}
