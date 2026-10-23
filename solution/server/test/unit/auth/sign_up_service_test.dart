import 'package:devtasks_server/src/generated/protocol.dart';
import 'package:devtasks_server/src/modules/auth/ports.dart';
import 'package:devtasks_server/src/modules/auth/sign_up_handler.dart';
import 'package:devtasks_server/src/modules/auth/sign_up_service.dart';
import 'package:test/test.dart';

class _Repo implements UserRepository {
  _Repo({this.existing = const {}});

  final Set<String> existing;

  @override
  Future<bool> existsByEmail(String normalizedEmail) async =>
      existing.contains(normalizedEmail);

  @override
  Future<CreateUserOutcome> create({
    required String name,
    required String email,
    required String passwordHash,
  }) async =>
      UserCreated(
        RegisteredUser(
          id: 'user-1',
          name: name,
          email: email,
          emailVerified: false,
        ),
      );
}

class _Hasher implements PasswordHasher {
  @override
  Future<String> hash(String password) async => 'hash::$password';
}

SignUpDto _dto({
  String name = 'Bia',
  String email = 'bia@ex.com',
  String password = 'F0rtress!Pass2026',
}) =>
    SignUpDto(name: name, email: email, password: password);

void main() {
  group('SignUpService — mapeamento do contrato', () {
    test('sucesso devolve userId e não devolve código de erro', () async {
      final service = SignUpService(SignUpHandler(_Repo(), _Hasher()));

      final result = await service.signUp(_dto());

      expect(result.success, isTrue);
      expect(result.userId, 'user-1');
      expect(result.errorCode, isNull);
    });

    test('duplicata devolve ERR_EMAIL_ALREADY_TAKEN', () async {
      final service = SignUpService(
        SignUpHandler(_Repo(existing: {'bia@ex.com'}), _Hasher()),
      );

      final result = await service.signUp(_dto(email: 'BIA@ex.com'));

      expect(result.success, isFalse);
      expect(result.errorCode, 'ERR_EMAIL_ALREADY_TAKEN');
    });

    test('senha inválida devolve ERR_VALIDATION com o campo', () async {
      final service = SignUpService(SignUpHandler(_Repo(), _Hasher()));

      final result = await service.signUp(_dto(password: 'curta1!A'));

      expect(result.success, isFalse);
      expect(result.errorCode, 'ERR_VALIDATION');
      expect(result.field, 'password');
    });

    test('sem adaptadores responde ERR_INFRA_FAILURE com mensagem neutra',
        () async {
      final service = SignUpService();

      final result = await service.signUp(_dto());

      expect(result.success, isFalse);
      expect(result.errorCode, 'ERR_INFRA_FAILURE');
      expect(result.message, isNot(contains('Adaptadores')));
    });
  });
}
