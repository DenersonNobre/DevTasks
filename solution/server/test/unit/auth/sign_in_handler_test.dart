import 'package:devtasks_server/src/modules/auth/ports.dart';
import 'package:devtasks_server/src/modules/auth/sign_in_handler.dart';
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
  int verifyCalls = 0;

  @override
  Future<bool> verify({
    required String password,
    required String passwordHash,
  }) async {
    verifyCalls++;
    return password == 'F0rtress!Pass2026' && passwordHash == 'hash::valid';
  }
}

SignInCommand _command({
  String email = '  BIA@Ex.COM ',
  String password = 'F0rtress!Pass2026',
}) =>
    SignInCommand(email: email, password: password);

void main() {
  group('SignInHandler — anti-enumeração (INV-SEC-04)', () {
    test('credenciais válidas devolvem sucesso com o usuário', () async {
      final verifier = _Verifier();
      final handler = SignInHandler(
        _Credentials(hashes: {'bia@ex.com': 'hash::valid'}),
        verifier,
      );

      final outcome = await handler.execute(_command());

      expect(outcome.isSuccess, isTrue);
      expect(outcome.user!.id, 'user-1');
      expect(verifier.verifyCalls, 1);
    });

    test('senha errada devolve ERR_INVALID_CREDENTIALS sem enumerar campo',
        () async {
      final handler = SignInHandler(
        _Credentials(hashes: {'bia@ex.com': 'hash::valid'}),
        _Verifier(),
      );

      final outcome = await handler.execute(_command(password: 'SenhaErrada1A'));

      expect(outcome.isSuccess, isFalse);
      expect(outcome.failure!.code, SignInErrorCode.invalidCredentials);
      expect(outcome.failure!.code.wireCode, 'ERR_INVALID_CREDENTIALS');
      expect(outcome.failure!.field, isNull);
    });

    test('e-mail inexistente devolve O MESMO erro e ainda verifica a senha',
        () async {
      final verifier = _Verifier();
      final handler = SignInHandler(_Credentials(), verifier);

      final outcome = await handler.execute(_command(email: 'nao@existe.com'));

      expect(outcome.isSuccess, isFalse);
      expect(outcome.failure!.code, SignInErrorCode.invalidCredentials);
      expect(outcome.failure!.field, isNull);
      expect(verifier.verifyCalls, 1,
          reason: 'verificação precisa rodar também sem usuário (timing)');
    });

    test('e-mail é normalizado antes da busca', () async {
      final handler = SignInHandler(
        _Credentials(hashes: {'bia@ex.com': 'hash::valid'}),
        _Verifier(),
      );

      final outcome = await handler.execute(_command(email: 'BIA@EX.COM'));

      expect(outcome.isSuccess, isTrue);
    });
  });

  group('SignInHandler — validação de entrada', () {
    test('e-mail malformado falha na validação sem verificar senha', () async {
      final verifier = _Verifier();
      final handler = SignInHandler(_Credentials(), verifier);

      final outcome = await handler.execute(_command(email: 'sem-arroba'));

      expect(outcome.isSuccess, isFalse);
      expect(outcome.failure!.code, SignInErrorCode.validation);
      expect(outcome.failure!.field, 'email');
      expect(verifier.verifyCalls, 0);
    });

    test('senha vazia falha na validação', () async {
      final handler = SignInHandler(_Credentials(), _Verifier());

      final outcome = await handler.execute(_command(password: ''));

      expect(outcome.isSuccess, isFalse);
      expect(outcome.failure!.code, SignInErrorCode.validation);
      expect(outcome.failure!.field, 'password');
    });
  });
}
