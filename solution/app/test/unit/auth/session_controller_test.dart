import 'package:devtasks_app/modules/auth/infrastructure/session_store.dart';
import 'package:devtasks_app/modules/auth/presentation/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSessionStore implements SessionStore {
  _FakeSessionStore([this.token]);

  String? token;
  int writes = 0;
  int clears = 0;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async {
    token = value;
    writes++;
  }

  @override
  Future<void> clear() async {
    token = null;
    clears++;
  }
}

void main() {
  group('SessionController — restauração (DoD F1.2)', () {
    test('sem token salvo o estado é signedOut', () async {
      final controller = SessionController(_FakeSessionStore());

      await controller.restore();

      expect(controller.state.status, SessionStatus.signedOut);
      expect(controller.state.token, isNull);
    });

    test('restaura sessão de um store com token (sobrevive a restart)',
        () async {
      // "restart" = novo controller lendo o mesmo store já preenchido.
      final store = _FakeSessionStore('token-opaco-abc');

      final controller = SessionController(store);
      await controller.restore();

      expect(controller.state.status, SessionStatus.authenticated);
      expect(controller.state.token, 'token-opaco-abc');
    });

    test('signIn persiste o token no store', () async {
      final store = _FakeSessionStore();
      final controller = SessionController(store);

      await controller.signIn('token-novo');

      expect(controller.state.status, SessionStatus.authenticated);
      expect(store.token, 'token-novo');
      expect(store.writes, 1);
    });

    test('signOut limpa o store e volta a signedOut', () async {
      final store = _FakeSessionStore('token-antigo');
      final controller = SessionController(store);
      await controller.restore();

      await controller.signOut();

      expect(controller.state.status, SessionStatus.signedOut);
      expect(store.token, isNull);
      expect(store.clears, 1);
    });

    test('estado é notificado aos ouvintes', () async {
      final controller = SessionController(_FakeSessionStore());
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.restore();
      await controller.signIn('t1');
      await controller.signOut();

      expect(notifications, 3);
    });
  });
}
