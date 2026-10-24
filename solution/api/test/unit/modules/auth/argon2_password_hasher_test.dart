import 'dart:convert';
import 'package:devtasks_api/modules/auth/argon2_password_hasher.dart';
import 'package:test/test.dart';

void main() {
  group('Argon2PasswordHasher — Parâmetros OWASP & Criptografia (INV-SEC-10)', () {
    final hasher = Argon2PasswordHasher(
      memoryKiB: 64,
      iterations: 1,
      parallelism: 1,
    );

    test('hash gerado é diferente da senha em texto claro', () async {
      const password = 'SecretPassword123!';
      final hash = await hasher.hash(password);

      expect(hash, isNot(contains(password)));
      expect(hash, startsWith(r'$argon2id$v=19$'));
    });

    test('verificação com senha correta retorna true', () async {
      const password = 'CorrectHorseBatteryStaple!';
      final hash = await hasher.hash(password);

      final verified = await hasher.verify(
        password: password,
        passwordHash: hash,
      );
      expect(verified, isTrue);
    });

    test('verificação com senha incorreta retorna false', () async {
      const password = 'CorrectPassword123!';
      final hash = await hasher.hash(password);

      final verified = await hasher.verify(
        password: 'WrongPassword456!',
        passwordHash: hash,
      );
      expect(verified, isFalse);
    });

    test(
      'duas chamadas para a mesma senha geram hashes com salts diferentes (CSPRNG)',
      () async {
        const password = 'DeterministicPassword!1';
        final hash1 = await hasher.hash(password);
        final hash2 = await hasher.hash(password);

        expect(hash1, isNot(equals(hash2)));

        final salt1 = hash1.split('\$')[4];
        final salt2 = hash2.split('\$')[4];
        expect(salt1, isNot(equals(salt2)));
        expect(base64.decode(salt1).length, 16);
        expect(base64.decode(salt2).length, 16);
      },
    );

    test('dummyHash canônico é válido e verificável sem erro', () async {
      final dummyVerifier = Argon2PasswordHasher();

      final verified = await dummyVerifier.verify(
        password: 'AttemptPassword123!',
        passwordHash: Argon2PasswordHasher.dummyHash,
      );

      expect(verified, isFalse);
    });

    test('hash malformado ou corrompido retorna false sem lançar exceção', () async {
      expect(
        await hasher.verify(password: 'pass', passwordHash: 'invalid-format'),
        isFalse,
      );
      expect(
        await hasher.verify(
          password: 'pass',
          passwordHash: r'$argon2i$v=19$m=64,t=1,p=1$AAAA$BBBB',
        ),
        isFalse,
        reason: 'Rejeita algoritmo que não seja argon2id',
      );
      expect(
        await hasher.verify(
          password: 'pass',
          passwordHash: r'$argon2id$v=16$m=64,t=1,p=1$AAAA$BBBB',
        ),
        isFalse,
        reason: 'Rejeita versão diferente de v=19',
      );
      expect(
        await hasher.verify(
          password: 'pass',
          passwordHash: r'$argon2id$v=19$m=bad,t=1,p=1$AAAA$BBBB',
        ),
        isFalse,
      );
    });

    test('produção usa parâmetros OWASP por padrão', () {
      const prodHasher = Argon2PasswordHasher();

      expect(prodHasher.memoryKiB, Argon2PasswordHasher.defaultMemoryKiB);
      expect(prodHasher.iterations, Argon2PasswordHasher.defaultIterations);
      expect(prodHasher.parallelism, Argon2PasswordHasher.defaultParallelism);
      expect(prodHasher.saltLength, Argon2PasswordHasher.defaultSaltLength);
      expect(prodHasher.derivedKeyLength, Argon2PasswordHasher.defaultKeyLength);

      expect(prodHasher.memoryKiB, 19456);
      expect(prodHasher.iterations, 2);
      expect(prodHasher.parallelism, 1);
      expect(prodHasher.saltLength, 16);
      expect(prodHasher.derivedKeyLength, 32);
    });
  });
}
