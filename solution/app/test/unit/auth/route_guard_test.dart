import 'package:devtasks_app/global/router/route_guard.dart';
import 'package:devtasks_app/modules/auth/domain/session_store.dart';
import 'package:devtasks_app/global/session/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const guard = RouteGuard();
  const signedOut = SessionState.signedOut();
  const authenticated = SessionState(
    status: SessionStatus.authenticated,
    token: 'token-opaco',
  );

  group('RouteGuard — rota privada exige sessão (DoD F1.3)', () {
    test('rota privada sem sessão redireciona ao login', () {
      expect(
        guard.decide(requiresSession: true, session: signedOut),
        RouteDecision.redirectToLogin,
      );
    });

    test('rota privada autenticada é permitida', () {
      expect(
        guard.decide(requiresSession: true, session: authenticated),
        RouteDecision.allow,
      );
    });

    test('rota pública é permitida mesmo sem sessão', () {
      expect(
        guard.decide(requiresSession: false, session: signedOut),
        RouteDecision.allow,
      );
    });

    test('após logout a rota privada volta a redirecionar', () async {
      final controller = _NoStore();
      final session = SessionController(controller);
      await session.signIn('token-opaco');

      expect(
        guard.decide(requiresSession: true, session: session.state),
        RouteDecision.allow,
      );

      await session.signOut();

      expect(
        guard.decide(requiresSession: true, session: session.state),
        RouteDecision.redirectToLogin,
      );
    });
  });
}

class _NoStore implements SessionStore {
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;

  @override
  Future<void> clear() async => token = null;
}
