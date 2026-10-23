import 'package:devtasks_server/src/modules/auth/ports.dart';
import 'package:devtasks_server/src/modules/auth/me_service.dart';
import 'package:devtasks_server/src/modules/auth/session_guard.dart';
import 'package:test/test.dart';

class _Auth implements SessionAuthenticator {
  @override
  Future<AuthenticatedUser?> authenticate(String token) async {
    if (token == 'valid-token') {
      return const AuthenticatedUser(id: 'user-1', email: 'bia@ex.com');
    }
    return null;
  }
}

void main() {
  group('MeService — contrato do endpoint privado (DoD F1.3)', () {
    test('sem token devolve ERR_NOT_AUTHENTICATED', () async {
      final service = MeService(SessionGuard(_Auth()));

      final result = await service.me(null);

      expect(result.success, isFalse);
      expect(result.errorCode, 'ERR_NOT_AUTHENTICATED');
      expect(result.message, SessionGuard.notAuthenticatedMessage);
      expect(result.userId, isNull);
    });

    test('token inválido devolve ERR_NOT_AUTHENTICATED', () async {
      final service = MeService(SessionGuard(_Auth()));

      final result = await service.me('invalido');

      expect(result.success, isFalse);
      expect(result.errorCode, 'ERR_NOT_AUTHENTICATED');
    });

    test('token válido devolve o usuário autenticado', () async {
      final service = MeService(SessionGuard(_Auth()));

      final result = await service.me('valid-token');

      expect(result.success, isTrue);
      expect(result.userId, 'user-1');
      expect(result.email, 'bia@ex.com');
      expect(result.errorCode, isNull);
    });

    test('autenticador padrão (sem emissão de token) nega sessão', () async {
      final service = MeService(SessionGuard(const NoSessionAuthenticator()));

      final result = await service.me('qualquer-token');

      expect(result.success, isFalse);
      expect(result.errorCode, 'ERR_NOT_AUTHENTICATED');
    });
  });
}
