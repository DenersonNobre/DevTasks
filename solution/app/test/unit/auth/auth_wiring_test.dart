import 'dart:convert';

import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/result.dart';
import 'package:devtasks_app/global/router/app_routes.dart';
import 'package:devtasks_app/global/session/.session.dart';
import 'package:devtasks_app/global/session/secure_session_store.dart';
import 'package:devtasks_app/global/shell/private_area_view.dart';
import 'package:devtasks_app/main.dart';
import 'package:devtasks_app/modules/auth/domain/auth_client.dart';
import 'package:devtasks_app/modules/auth/infrastructure/auth_client_provider.dart';
import 'package:devtasks_app/modules/auth/infrastructure/http_auth_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeKeyValueStore implements ISecureKeyValueStore {
  final Map<String, String> data = {};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    data.remove(key);
  }
}

/// UUID de teste (contrato `format: uuid`).
const _userId = '00000000-0000-4000-8000-000000000042';

HttpAuthClient _clientReturning(
  int status,
  Map<String, Object?> body, {
  void Function(http.Request request)? onRequest,
}) {
  final mock = MockClient((request) async {
    onRequest?.call(request);
    return http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );
  });
  return HttpAuthClient(client: mock, baseUrl: 'http://api.test');
}

void main() {
  group('UC-08.07 — Wiring do App: adaptador HTTP, Guard & Boot', () {
    test('Round-trip no SecureSessionStore via SecureKeyValueStore', () async {
      final kvStore = _FakeKeyValueStore();
      final store = SecureSessionStore(kvStore);

      expect(await store.read(), isNull);

      await store.write('token-abc-123');
      expect(await store.read(), equals('token-abc-123'));
      expect(kvStore.data[SessionStorageKeys.sessionToken], equals('token-abc-123'));

      await store.clear();
      expect(await store.read(), isNull);
      expect(kvStore.data.containsKey(SessionStorageKeys.sessionToken), isFalse);
    });

    group('HttpAuthClient — mapeamento errorCode -> IFailure', () {
      final table = <String, Type>{
        'ERR_INVALID_CREDENTIALS': InvalidCredentialsFailure,
        'ERR_EMAIL_ALREADY_TAKEN': EmailAlreadyTakenFailure,
        'ERR_VALIDATION': ValidationFailure,
        'ERR_RATE_LIMITED': RateLimitedFailure,
        'ERR_NOT_AUTHENTICATED': NotAuthenticatedFailure,
        'ERR_INSUFFICIENT_ROLE': InsufficientRoleFailure,
        'ERR_NOT_FOUND': NotFoundFailure,
        'ERR_QUALQUER_OUTRO': InfraFailure,
      };

      for (final entry in table.entries) {
        test('mapeia ${entry.key} para ${entry.value}', () async {
          final client = _clientReturning(400, {
            'errorCode': entry.key,
            'message': 'Mensagem de teste',
          });

          final result = await client.signIn(
            email: 'user@ex.com',
            password: 'Password123!',
          );

          expect(result, isA<Failure>());
          expect((result as Failure).failure.runtimeType, equals(entry.value));
        });
      }

      test('ERR_VALIDATION preserva o campo do envelope', () async {
        final client = _clientReturning(400, {
          'errorCode': 'ERR_VALIDATION',
          'message': 'E-mail inválido.',
          'field': 'email',
        });

        final result = await client.signIn(email: 'x', password: 'y');

        final failure = (result as Failure).failure as ValidationFailure;
        expect(failure.field, 'email');
      });
    });

    group('HttpAuthClient — contrato de sucesso', () {
      test('signIn devolve AuthSession com userId UUID e token', () async {
        late http.Request captured;
        final client = _clientReturning(
          200,
          {'sessionToken': 'token-valido', 'userId': _userId},
          onRequest: (request) => captured = request,
        );

        final result = await client.signIn(
          email: 'user@ex.com',
          password: 'Password123!',
        );

        expect(result, isA<Success>());
        final session = (result as Success).value as AuthSession;
        expect(session.userId, _userId);
        expect(session.token, 'token-valido');
        expect(captured.url.path, '/auth/signin');
        expect(captured.headers['content-type'], contains('application/json'));
      });

      test('signUp devolve o userId UUID (201)', () async {
        final client = _clientReturning(201, {'userId': _userId});

        final result = await client.signUp(
          name: 'Nome Teste',
          email: 'user@ex.com',
          password: 'Password123!',
        );

        expect(result, isA<Success>());
        expect((result as Success).value, _userId);
      });

      test('signOut envia Bearer e aceita 200', () async {
        late http.Request captured;
        final client = _clientReturning(
          200,
          <String, Object?>{},
          onRequest: (request) => captured = request,
        );

        final result = await client.signOut('token-segredo');

        expect(result, isA<Success>());
        expect(captured.headers['authorization'], 'Bearer token-segredo');
        expect(captured.url.path, '/auth/signout');
      });

      test('resposta 200 sem sessionToken é tratada como falha tipada', () async {
        final client = _clientReturning(200, {'userId': _userId});

        final result = await client.signIn(email: 'a@b.c', password: 'x');

        expect(result, isA<Failure>());
      });

      test('status de erro sem envelope não lança exceção', () async {
        final mock = MockClient((_) async => http.Response('', 503));
        final client = HttpAuthClient(client: mock, baseUrl: 'http://api.test');

        final result = await client.signIn(email: 'a@b.c', password: 'x');

        expect(result, isA<Failure>());
        expect((result as Failure).failure, isA<InfraFailure>());
      });
    });

    test('Boot: sessão persistida é restaurada no SessionController', () async {
      final kvStore = _FakeKeyValueStore();
      final store = SecureSessionStore(kvStore);
      await store.write('token-restaurado-no-boot');

      final controller = SessionController(store);
      expect(controller.state.isAuthenticated, isFalse);

      await controller.restore();
      expect(controller.state.isAuthenticated, isTrue);
      expect(controller.state.token, equals('token-restaurado-no-boot'));
    });

    testWidgets('RouteGuard redireciona rota privada sem sessão para login', (tester) async {
      final kvStore = _FakeKeyValueStore();
      final store = SecureSessionStore(kvStore);
      final controller = SessionController(store);
      final authClient = _clientReturning(500, <String, Object?>{});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authClientProvider.overrideWithValue(authClient),
            sessionStoreProvider.overrideWithValue(store),
            sessionControllerProvider.overrideWith((ref) => controller),
          ],
          child: const DevTasksApp(initialRoute: AppRoutes.privateArea),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login-submit')), findsOneWidget);
      expect(find.byType(PrivateAreaView), findsNothing);
    });

    testWidgets('RouteGuard redireciona rota pública com sessão para área privada', (tester) async {
      final kvStore = _FakeKeyValueStore();
      final store = SecureSessionStore(kvStore);
      final controller = SessionController(store);
      await controller.signIn('token-autenticado');

      final authClient = _clientReturning(500, <String, Object?>{});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authClientProvider.overrideWithValue(authClient),
            sessionStoreProvider.overrideWithValue(store),
            sessionControllerProvider.overrideWith((ref) => controller),
          ],
          child: const DevTasksApp(initialRoute: AppRoutes.login),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PrivateAreaView), findsOneWidget);
      expect(find.byKey(const Key('private-logout')), findsOneWidget);
    });

    testWidgets('Logout limpa store e atualiza estado mesmo se a rede falhar', (tester) async {
      final kvStore = _FakeKeyValueStore();
      final store = SecureSessionStore(kvStore);
      await store.write('token-pre-logout');

      final controller = SessionController(store);
      await controller.restore();

      final authClient = _clientReturning(500, {
        'errorCode': 'ERR_INFRA_FAILURE',
        'message': 'falha simulada',
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authClientProvider.overrideWithValue(authClient),
            sessionStoreProvider.overrideWithValue(store),
            sessionControllerProvider.overrideWith((ref) => controller),
          ],
          child: const DevTasksApp(initialRoute: AppRoutes.privateArea),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PrivateAreaView), findsOneWidget);
      expect(find.byKey(const Key('private-logout')), findsOneWidget);

      await tester.tap(find.byKey(const Key('private-logout')));
      await tester.pumpAndSettle();

      expect(await store.read(), isNull);
      expect(controller.state.isAuthenticated, isFalse);
      expect(find.byKey(const Key('login-submit')), findsOneWidget);
    });
  });
}
