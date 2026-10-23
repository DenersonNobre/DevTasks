import 'package:devtasks_server/src/modules/auth/ports.dart';
import 'package:devtasks_server/src/modules/auth/sign_up_handler.dart';
import 'package:test/test.dart';

class _Created {
  const _Created({
    required this.name,
    required this.email,
    required this.passwordHash,
  });

  final String name;
  final String email;
  final String passwordHash;
}

class _FakeUserRepository implements UserRepository {
  _FakeUserRepository({
    this.existingEmails = const {},
    this.failOnCreateEmails = const {},
  });

  final Set<String> existingEmails;
  final Set<String> failOnCreateEmails;
  final List<_Created> created = [];

  @override
  Future<bool> existsByEmail(String normalizedEmail) async =>
      existingEmails.contains(normalizedEmail);

  @override
  Future<CreateUserOutcome> create({
    required String name,
    required String email,
    required String passwordHash,
  }) async {
    if (failOnCreateEmails.contains(email)) {
      return const EmailTaken();
    }

    final user = RegisteredUser(
      id: 'user-${created.length + 1}',
      name: name,
      email: email,
      emailVerified: false,
    );
    created.add(_Created(name: name, email: email, passwordHash: passwordHash));
    return UserCreated(user);
  }
}

class _SpyPasswordHasher implements PasswordHasher {
  int hashCalls = 0;

  @override
  Future<String> hash(String password) async {
    hashCalls++;
    return 'argon2id::fake::$password';
  }
}

SignUpCommand _command({
  String name = 'Bia',
  String email = '  BIA@Ex.COM ',
  String password = 'F0rtress!Pass2026',
}) =>
    SignUpCommand(name: name, email: email, password: password);

void main() {
  group('SignUpHandler — INV-08 (normalização e unicidade)', () {
    test('normaliza e-mail (trim + lowercase) antes de persistir', () async {
      final repository = _FakeUserRepository();
      final handler = SignUpHandler(repository, _SpyPasswordHasher());

      final outcome = await handler.execute(_command());

      expect(outcome.isSuccess, isTrue);
      expect(repository.created.single.email, 'bia@ex.com');
      expect(repository.created.single.name, 'Bia');
    });

    test('e-mail duplicado (qualquer caixa) falha com emailAlreadyTaken',
        () async {
      final repository = _FakeUserRepository(existingEmails: {'bia@ex.com'});
      final hasher = _SpyPasswordHasher();
      final handler = SignUpHandler(repository, hasher);

      final outcome = await handler.execute(_command(email: 'BIA@ex.com'));

      expect(outcome.isSuccess, isFalse);
      expect(outcome.failure!.code, SignUpErrorCode.emailAlreadyTaken);
      expect(repository.created, isEmpty);
      expect(hasher.hashCalls, 1,
          reason: 'hash precisa rodar também no caminho de duplicata (timing)');
    });

    test(
        'corrida TOCTOU (existsByEmail passa, mas create colide) devolve emailAlreadyTaken',
        () async {
      // Simula condição de corrida: existsByEmail retorna false, mas uma requisição
      // concorrente inseriu primeiro e o banco disparou violação de unicidade (SQLSTATE 23505).
      // A prova ponta-a-ponta com PostgreSQL real fica no CI.
      final repository = _FakeUserRepository(
        existingEmails: {},
        failOnCreateEmails: {'bia@ex.com'},
      );
      final hasher = _SpyPasswordHasher();
      final handler = SignUpHandler(repository, hasher);

      final outcome = await handler.execute(_command(email: 'bia@ex.com'));

      expect(outcome.isSuccess, isFalse);
      expect(outcome.failure!.code, SignUpErrorCode.emailAlreadyTaken);
      expect(outcome.failure!.message, 'Este e-mail já está em uso.');
      expect(outcome.failure!.field, 'email');
    });

    test('e-mail sem formato válido falha com validação e sem hash', () async {
      final hasher = _SpyPasswordHasher();
      final handler = SignUpHandler(_FakeUserRepository(), hasher);

      final outcome = await handler.execute(_command(email: 'sem-arroba'));

      expect(outcome.isSuccess, isFalse);
      expect(outcome.failure!.code, SignUpErrorCode.validation);
      expect(outcome.failure!.field, 'email');
      expect(hasher.hashCalls, 0);
    });
  });

  group('SignUpHandler — INV-SEC-08 (política de senha)', () {
    for (final invalid in [
      'curta1!A', // 9 caracteres
      'SemDigito!Aaaaa',
      'semmaiuscula1a', // sem maiúscula
      'SEMMAIUSCULA1A', // sem minúscula
    ]) {
      test('rejeita senha inválida "$invalid" sem chamar o hasher', () async {
        final hasher = _SpyPasswordHasher();
        final handler = SignUpHandler(_FakeUserRepository(), hasher);

        final outcome = await handler.execute(_command(password: invalid));

        expect(outcome.isSuccess, isFalse);
        expect(outcome.failure!.code, SignUpErrorCode.validation);
        expect(outcome.failure!.field, 'password');
        expect(hasher.hashCalls, 0,
            reason: 'senha inválida não pode custar hash/CPU');
      });
    }

    test('aceita senha válida e persiste com o nome normalizado', () async {
      final repository = _FakeUserRepository();
      final handler = SignUpHandler(repository, _SpyPasswordHasher());

      final outcome = await handler.execute(_command(name: '  Bia  '));

      expect(outcome.isSuccess, isTrue);
      expect(repository.created.single.name, 'Bia');
    });
  });

  group('SignUpHandler — nome obrigatório (RF-01)', () {
    test('nome vazio falha na validação sem chamar o hasher', () async {
      final hasher = _SpyPasswordHasher();
      final handler = SignUpHandler(_FakeUserRepository(), hasher);

      final outcome = await handler.execute(_command(name: '   '));

      expect(outcome.isSuccess, isFalse);
      expect(outcome.failure!.code, SignUpErrorCode.validation);
      expect(outcome.failure!.field, 'name');
      expect(hasher.hashCalls, 0);
    });
  });
}
