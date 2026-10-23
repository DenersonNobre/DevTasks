import 'package:devtasks_server/src/modules/auth/ports.dart';
import 'package:devtasks_server/src/modules/auth/session_guard.dart';
import 'package:test/test.dart';

class _Auth implements SessionAuthenticator {
  int calls = 0;

  @override
  Future<AuthenticatedUser?> authenticate(String token) async {
    calls++;
    if (token == 'valid-token') {
      return const AuthenticatedUser(id: 'user-1', email: 'bia@ex.com');
    }
    return null;
  }
}

void main() {
  group('SessionGuard — endpoint privado exige sessão (DoD F1.3)', () {
    test('token nulo falha com ERR_NOT_AUTHENTICATED sem consultar', () async {
      final auth = _Auth();
      final outcome = await SessionGuard(auth).requireSession(null);

      expect(outcome.isAuthorized, isFalse);
      expect(outcome.code!.wireCode, 'ERR_NOT_AUTHENTICATED');
      expect(auth.calls, 0);
    });

    test('token vazio falha com ERR_NOT_AUTHENTICATED', () async {
      final outcome = await SessionGuard(_Auth()).requireSession('');

      expect(outcome.isAuthorized, isFalse);
      expect(outcome.code!.wireCode, 'ERR_NOT_AUTHENTICATED');
    });

    test('token inválido falha com ERR_NOT_AUTHENTICATED', () async {
      final auth = _Auth();
      final outcome = await SessionGuard(auth).requireSession('invalido');

      expect(outcome.isAuthorized, isFalse);
      expect(outcome.code!.wireCode, 'ERR_NOT_AUTHENTICATED');
      expect(auth.calls, 1);
    });

    test('token válido autoriza e devolve o usuário', () async {
      final outcome = await SessionGuard(_Auth()).requireSession('valid-token');

      expect(outcome.isAuthorized, isTrue);
      expect(outcome.user!.id, 'user-1');
      expect(outcome.user!.email, 'bia@ex.com');
    });
  });
}
