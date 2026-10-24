import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/key_derivators/argon2.dart';
import 'package:pointycastle/pointycastle.dart';

import 'ports.dart';

/// Implementação do `PasswordHasher` e `PasswordVerifier` utilizando Argon2id
/// conforme recomendações da OWASP Password Storage Cheat Sheet.
///
/// Parâmetros OWASP de produção:
/// - Memória ($m$): 19456 KiB (19 MiB)
/// - Iterações ($t$): 2
/// - Paralelismo ($p$): 1
/// - Comprimento do Salt: 16 bytes gerados via CSPRNG (`Random.secure()`, INV-SEC-10)
/// - Comprimento da chave derivada: 32 bytes (256 bits)
/// - Versão: Argon2 v13 (19 / 0x13)
///
/// Formato de hash versionado e autodescritivo (PHC string format, RFC 9106):
/// `$argon2id$v=19$m=19456,t=2,p=1$<salt_base64>$<hash_base64>`
class Argon2PasswordHasher implements IPasswordHasher, IPasswordVerifier {
  const Argon2PasswordHasher({
    this.memoryKiB = defaultMemoryKiB,
    this.iterations = defaultIterations,
    this.parallelism = defaultParallelism,
    this.derivedKeyLength = defaultKeyLength,
    this.saltLength = defaultSaltLength,
    this.random,
  });

  /// Parâmetro de memória padrão OWASP: 19456 KiB (~19 MiB).
  static const int defaultMemoryKiB = 19456;

  /// Parâmetro de iterações padrão OWASP: 2 passadas.
  static const int defaultIterations = 2;

  /// Grau de paralelismo padrão: 1 lane / thread.
  static const int defaultParallelism = 1;

  /// Tamanho da chave derivada / tag: 32 bytes (256 bits).
  static const int defaultKeyLength = 32;

  /// Tamanho do salt criptográfico: 16 bytes (128 bits, INV-SEC-10).
  static const int defaultSaltLength = 16;

  /// Hash dummy canônico válido pré-computado com parâmetros OWASP.
  ///
  /// Utilizado por `SignInHandler` para blindar o timing attack (INV-SEC-04)
  /// em caso de usuário não encontrado, sem falhar no parse de formato e
  /// garantindo tempo de CPU idêntico ao de uma senha real.
  static const String dummyHash =
      r'$argon2id$v=19$m=19456,t=2,p=1$AAAAAAAAAAAAAAAAAAAAAA==$XuWpLPw6ty350Ater6UtNshJdgMODNFLeD6eZt3/hL0=';

  final int memoryKiB;
  final int iterations;
  final int parallelism;
  final int derivedKeyLength;
  final int saltLength;
  final Random? random;

  @override
  Future<String> hash(String password) async {
    final salt = _generateSecureSalt(saltLength);
    final derived = _derive(
      password: password,
      salt: salt,
      iterations: iterations,
      memoryKiB: memoryKiB,
      parallelism: parallelism,
      keyLength: derivedKeyLength,
    );

    final saltB64 = base64.encode(salt);
    final hashB64 = base64.encode(derived);

    return '\$argon2id\$v=19\$m=$memoryKiB,t=$iterations,p=$parallelism\$$saltB64\$$hashB64';
  }

  @override
  Future<bool> verify({
    required String password,
    required String passwordHash,
  }) async {
    final parsed = _parseHash(passwordHash);
    if (parsed == null) {
      return false;
    }

    final computed = _derive(
      password: password,
      salt: parsed.salt,
      iterations: parsed.iterations,
      memoryKiB: parsed.memoryKiB,
      parallelism: parsed.parallelism,
      keyLength: parsed.hashBytes.length,
    );

    return _constantTimeEquals(computed, parsed.hashBytes);
  }

  Uint8List _generateSecureSalt(int length) {
    final rng = random ?? Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = rng.nextInt(256);
    }
    return bytes;
  }

  Uint8List _derive({
    required String password,
    required Uint8List salt,
    required int iterations,
    required int memoryKiB,
    required int parallelism,
    required int keyLength,
  }) {
    final generator = Argon2BytesGenerator();
    final parameters = Argon2Parameters(
      Argon2Parameters.ARGON2_id,
      salt,
      desiredKeyLength: keyLength,
      version: Argon2Parameters.ARGON2_VERSION_13,
      iterations: iterations,
      memory: memoryKiB,
      lanes: parallelism,
    );
    generator.init(parameters);

    final passwordBytes = Uint8List.fromList(utf8.encode(password));
    return generator.process(passwordBytes);
  }

  _ParsedArgon2Hash? _parseHash(String encoded) {
    final parts = encoded.split('\$');
    // Espera formato: ['', 'argon2id', 'v=19', 'm=...,t=...,p=...', 'saltB64', 'hashB64']
    if (parts.length != 6 || parts[1] != 'argon2id') {
      return null;
    }

    final versionStr = parts[2];
    if (versionStr != 'v=19') {
      return null;
    }

    int? memoryKiB;
    int? iterations;
    int? parallelism;

    final paramPairs = parts[3].split(',');
    for (final pair in paramPairs) {
      final kv = pair.split('=');
      if (kv.length != 2) return null;
      final val = int.tryParse(kv[1]);
      if (val == null) return null;

      switch (kv[0]) {
        case 'm':
          memoryKiB = val;
        case 't':
          iterations = val;
        case 'p':
          parallelism = val;
      }
    }

    if (memoryKiB == null || iterations == null || parallelism == null) {
      return null;
    }

    Uint8List salt;
    Uint8List hashBytes;
    try {
      salt = Uint8List.fromList(base64.decode(parts[4]));
      hashBytes = Uint8List.fromList(base64.decode(parts[5]));
    } catch (_) {
      return null;
    }

    if (salt.isEmpty || hashBytes.isEmpty) {
      return null;
    }

    return _ParsedArgon2Hash(
      memoryKiB: memoryKiB,
      iterations: iterations,
      parallelism: parallelism,
      salt: salt,
      hashBytes: hashBytes,
    );
  }

  /// Comparação em tempo constante para mitigar side-channel timing attacks.
  bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) {
      return false;
    }
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}

class _ParsedArgon2Hash {
  const _ParsedArgon2Hash({
    required this.memoryKiB,
    required this.iterations,
    required this.parallelism,
    required this.salt,
    required this.hashBytes,
  });

  final int memoryKiB;
  final int iterations;
  final int parallelism;
  final Uint8List salt;
  final Uint8List hashBytes;
}

