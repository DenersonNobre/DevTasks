import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/result.dart';
import 'package:devtasks_app/global/router/app_routes.dart';
import 'package:devtasks_app/global/session/.session.dart';
import 'package:devtasks_app/global/session/secure_session_store.dart';
import 'package:devtasks_app/main.dart';
import 'package:devtasks_app/modules/auth/infrastructure/auth_client_provider.dart';
import 'package:devtasks_app/modules/auth/infrastructure/serverpod_auth_client.dart';
import 'package:devtasks_client/devtasks_client.dart' as client;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeKeyValueStore implements SecureKeyValueStore {
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

class _FakeEndpointAuth implements client.EndpointAuth {
  _FakeEndpointAuth({
    this.signInResponse,
    this.signUpResponse,
    this.signOutResponse,
  });

  client.SignInResultDto? signInResponse;
  client.SignUpResultDto? signUpResponse;
  client.SignOutResultDto? signOutResponse;

  @override
  Future<client.SignInResultDto> signIn(client.SignInDto dto) async {
    return signInResponse ?? client.SignInResultDto(success: false);
  }

  @override
  Future<client.SignUpResultDto> signUp(client.SignUpDto dto) async {
    return signUpResponse ?? client.SignUpResultDto(success: false);
  }

  @override
  Future<client.SignOutResultDto> signOut() async {
    return signOutResponse ?? client.SignOutResultDto(success: true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeClient implements client.Client {
  _FakeClient(this.authEndpoint);

  final client.EndpointAuth authEndpoint;

  @override
  client.EndpointAuth get auth => authEndpoint;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('UC-01.08 — Wiring Real do App: Adaptadores, Guard & Boot', () {
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

    group('ServerpodAuthClient — Mapeamento exhaustivo errorCode -> IFailure', () {
      final table = <String, Type>{
        'ERR_INVALID_CREDENTIALS': InvalidCredentialsFailure,
        'ERR_EMAIL_ALREADY_TAKEN': EmailAlreadyTakenFailure,
        'ERR_VALIDATION': ValidationFailure,
        'ERR_RATE_LIMITED': RateLimitedFailure,
        'ERR_NOT_AUTHENTICATED': NotAuthenticatedFailure,
        'ERR_QUALQUER_OUTRO': InfraFailure,
      };

      for (final entry in table.entries) {
        test('Mapeia ${entry.key} para ${entry.value}', () async {
          final endpoint = _FakeEndpointAuth(
            signInResponse: client.SignInResultDto(
              success: false,
              errorCode: entry.key,
              message: 'Mensagem de teste',
            ),
          );
          final authClient = ServerpodAuthClient(client: _FakeClient(endpoint));

          final result = await authClient.signIn(
            email: 'user@ex.com',
            password: 'Password123!',
          );

          expect(result, isA<Failure>());
          final failure = (result as Failure).failure;
          expect(failure.runtimeType, equals(entry.value));
        });
      }

      test('Sucesso em signIn devolve AuthSession com token e userId', () async {
        final endpoint = _FakeEndpointAuth(
          signInResponse: client.SignInResultDto(
            success: true,
            userId: '42',
            sessionToken: 'token-gerado-valido',
          ),
        );
        final authClient = ServerpodAuthClient(client: _FakeClient(endpoint));

        final result = await authClient.signIn(
          email: 'user@ex.com',
          password: 'Password123!',
        );

        expect(result, isA<Success>());
        final session = (result as Success).value;
        expect(session.userId, equals(42));
        expect(session.token, equals('token-gerado-valido'));
      });

      test('Sucesso em signUp devolve userId', () async {
        final endpoint = _FakeEndpointAuth(
          signUpResponse: client.SignUpResultDto(
            success: true,
            userId: '42',
          ),
        );
        final authClient = ServerpodAuthClient(client: _FakeClient(endpoint));

        final result = await authClient.signUp(
          name: 'Nome Teste',
          email: 'user@ex.com',
          password: 'Password123!',
        );

        expect(result, isA<Success>());
        final userId = (result as Success).value;
        expect(userId, equals(42));
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

    testWidgets('RouteGuard no onGenerateRoute redireciona rota privada sem sessão para login', (tester) async {
      final kvStore = _FakeKeyValueStore();
      final store = SecureSessionStore(kvStore);
      final controller = SessionController(store);
      final endpoint = _FakeEndpointAuth();
      final authClient = ServerpodAuthClient(client: _FakeClient(endpoint));

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
      expect(find.text('Área privada (EPIC-02)'), findsNothing);
    });

    testWidgets('RouteGuard no onGenerateRoute redireciona rota pública com sessão para área privada', (tester) async {
      final kvStore = _FakeKeyValueStore();
      final store = SecureSessionStore(kvStore);
      final controller = SessionController(store);
      await controller.signIn('token-autenticado');

      final endpoint = _FakeEndpointAuth();
      final authClient = ServerpodAuthClient(client: _FakeClient(endpoint));

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

      expect(find.text('Área privada (EPIC-02)'), findsOneWidget);
      expect(find.text('Sessão ativa'), findsOneWidget);
    });

    testWidgets('Logout limpa store e atualiza estado mesmo se rede falhar', (tester) async {
      final kvStore = _FakeKeyValueStore();
      final store = SecureSessionStore(kvStore);
      await store.write('token-pre-logout');

      final controller = SessionController(store);
      await controller.restore();

      final endpoint = _FakeEndpointAuth(
        signOutResponse: client.SignOutResultDto(
          success: false,
          errorCode: 'ERR_INFRA_FAILURE',
        ),
      );
      final authClient = ServerpodAuthClient(client: _FakeClient(endpoint));

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

      expect(find.text('Área privada (EPIC-02)'), findsOneWidget);

      // Clica em 'Sair'
      await tester.tap(find.byKey(const Key('private-logout')));
      await tester.pumpAndSettle();

      // Verifica limpeza do store local e redirecionamento para o login
      expect(await store.read(), isNull);
      expect(controller.state.isAuthenticated, isFalse);
      expect(find.byKey(const Key('login-submit')), findsOneWidget);
    });
  });
}
