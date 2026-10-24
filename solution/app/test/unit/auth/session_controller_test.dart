import 'package:devtasks_app/global/session/.session.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSessionStore implements ISessionStore {
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

    test('token vazio no store também não autentica', () async {
      final controller = SessionController(_FakeSessionStore(''));

      await controller.restore();

      expect(controller.state.status, SessionStatus.signedOut);
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

    test('round-trip: signIn(A) → novo controller(B) restaura o mesmo token',
        () async {
      final store = _FakeSessionStore();
      final a = SessionController(store);
      await a.signIn('token-round-trip');

      // Simula restart: outro controller sobre o MESMO store.
      final b = SessionController(store);
      await b.restore();

      expect(b.state.status, SessionStatus.authenticated);
      expect(b.state.token, a.state.token);
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
