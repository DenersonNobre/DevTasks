import 'package:devtasks_server/src/generated/protocol.dart';
import 'package:devtasks_server/src/modules/auth/ports.dart';
import 'package:devtasks_server/src/modules/auth/sign_in_handler.dart';
import 'package:devtasks_server/src/modules/auth/sign_in_service.dart';
import 'package:test/test.dart';

class _Credentials implements CredentialRepository {
  _Credentials({Map<String, String>? hashes}) : _hashes = hashes ?? {};

  final Map<String, String> _hashes;

  @override
  Future<CredentialRecord?> findByEmail(String normalizedEmail) async {
    final hash = _hashes[normalizedEmail];
    if (hash == null) return null;
    return CredentialRecord(
      id: 'user-1',
      email: normalizedEmail,
      passwordHash: hash,
    );
  }
}

class _Verifier implements PasswordVerifier {
  @override
  Future<bool> verify({
    required String password,
    required String passwordHash,
  }) async =>
      password == 'F0rtress!Pass2026' && passwordHash == 'hash::valid';
}

SignInDto _dto({
  String email = 'bia@ex.com',
  String password = 'F0rtress!Pass2026',
}) =>
    SignInDto(email: email, password: password);

void main() {
  group('SignInService — mapeamento do contrato (401)', () {
    test('sucesso devolve userId, sem código de erro e sem token neste slice',
        () async {
      final service = SignInService(
        SignInHandler(_Credentials(hashes: {'bia@ex.com': 'hash::valid'}), _Verifier()),
      );

      final result = await service.signIn(_dto());

      expect(result.success, isTrue);
      expect(result.userId, 'user-1');
      expect(result.errorCode, isNull);
      expect(result.sessionToken, isNull);
    });

    test('credencial inválida devolve ERR_INVALID_CREDENTIALS sem campo',
        () async {
      final service = SignInService(
        SignInHandler(
          _Credentials(hashes: {'bia@ex.com': 'hash::valid'}),
          _Verifier(),
        ),
      );

      final result = await service.signIn(_dto(password: 'SenhaErrada1A'));

      expect(result.success, isFalse);
      expect(result.errorCode, 'ERR_INVALID_CREDENTIALS');
      expect(result.field, isNull);
      expect(result.message, SignInHandler.invalidCredentialsMessage);
    });

    test('sem adaptadores responde ERR_INFRA_FAILURE com mensagem neutra',
        () async {
      final service = SignInService();

      final result = await service.signIn(_dto());

      expect(result.success, isFalse);
      expect(result.errorCode, 'ERR_INFRA_FAILURE');
      expect(result.message, isNot(contains('adaptadores')));
    });
  });
}
