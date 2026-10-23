import 'dart:async';

import 'package:devtasks_app/global/kernel/.kernel.dart';
import 'package:devtasks_app/global/router/app_routes.dart';
import 'package:devtasks_app/global/session/.session.dart';
import 'package:devtasks_app/global/shell/private_area_view.dart';
import 'package:devtasks_app/modules/auth/.auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_auth_client.dart';
import '../support/in_memory_session_store.dart';

const _validEmail = 'user@example.com';
const _validPassword = 'SenhaForte123';

Widget _harness({
  required Widget home,
  required FakeAuthClient client,
  required InMemorySessionStore store,
}) {
  return ProviderScope(
    overrides: [
      authClientProvider.overrideWithValue(client),
      sessionStoreProvider.overrideWithValue(store),
    ],
    child: MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (_) => home,
        AppRoutes.login: (_) => const LoginView(),
        AppRoutes.register: (_) => const RegisterView(),
        AppRoutes.privateArea: (_) => const PrivateAreaView(),
      },
    ),
  );
}

Future<void> _fillLogin(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('login-email')), _validEmail);
  await tester.enterText(find.byKey(const Key('login-password')), _validPassword);
}

Future<void> _fillRegister(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('register-name')), 'Ana Silva');
  await tester.enterText(find.byKey(const Key('register-email')), _validEmail);
  await tester.enterText(find.byKey(const Key('register-password')), _validPassword);
}

void main() {
  late FakeAuthClient client;
  late InMemorySessionStore store;

  setUp(() {
    client = FakeAuthClient();
    store = InMemorySessionStore();
  });

  group('LoginView — estados (DoD F1.6)', () {
    testWidgets('idle: campos visíveis, senha obscura e submit habilitado', (tester) async {
      await tester.pumpWidget(
        _harness(home: const LoginView(), client: client, store: store),
      );

      expect(find.byKey(const Key('login-email')), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byKey(const Key('login-password'))).obscureText,
        isTrue,
      );
      expect(
        tester.widget<FilledButton>(find.byKey(const Key('login-submit'))).onPressed,
        isNotNull,
      );
    });

    testWidgets('validação: e-mail inválido aparece inline e nada é enviado', (tester) async {
      await tester.pumpWidget(
        _harness(home: const LoginView(), client: client, store: store),
      );
      await tester.enterText(find.byKey(const Key('login-email')), 'invalido');
      await tester.enterText(find.byKey(const Key('login-password')), _validPassword);
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle();

      expect(find.text('E-mail inválido.'), findsOneWidget);
      expect(client.signInCalls, 0);
    });

    testWidgets('loading: indicador visível e botão desabilitado', (tester) async {
      client.pendingSignIn = Completer<IResult<AuthSession, IFailure>>();
      await tester.pumpWidget(
        _harness(home: const LoginView(), client: client, store: store),
      );
      await _fillLogin(tester);
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byKey(const Key('login-submit'))).onPressed,
        isNull,
      );

      client.pendingSignIn!.complete(const Success(AuthSession(userId: 1, token: 'tok')));
      await tester.pumpAndSettle();
    });

    testWidgets('error: mensagem única de credencial inválida', (tester) async {
      client.signInResult = Failure(const InvalidCredentialsFailure());
      await tester.pumpWidget(
        _harness(home: const LoginView(), client: client, store: store),
      );
      await _fillLogin(tester);
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login-form-error')), findsOneWidget);
      expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
    });

    testWidgets('completed: navega para a área privada e persiste o token', (tester) async {
      client.signInResult = const Success(AuthSession(userId: 7, token: 'tok-123'));
      await tester.pumpWidget(
        _harness(home: const LoginView(), client: client, store: store),
      );
      await _fillLogin(tester);
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Área privada (EPIC-02)'), findsOneWidget);
      expect(store.token, 'tok-123');
    });
  });

  group('RegisterView — estados (DoD F1.6)', () {
    testWidgets('renderiza campos e senha obscura', (tester) async {
      await tester.pumpWidget(
        _harness(home: const RegisterView(), client: client, store: store),
      );

      expect(find.byKey(const Key('register-name')), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byKey(const Key('register-password'))).obscureText,
        isTrue,
      );
    });

    testWidgets('e-mail já cadastrado mostra erro único', (tester) async {
      client.signUpResult = Failure(const EmailAlreadyTakenFailure());
      await tester.pumpWidget(
        _harness(home: const RegisterView(), client: client, store: store),
      );
      await _fillRegister(tester);
      await tester.tap(find.byKey(const Key('register-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Este e-mail já está em uso.'), findsOneWidget);
    });

    testWidgets('sucesso volta para o login', (tester) async {
      client.signUpResult = const Success(42);
      await tester.pumpWidget(
        _harness(home: const RegisterView(), client: client, store: store),
      );
      await _fillRegister(tester);
      await tester.tap(find.byKey(const Key('register-submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login-submit')), findsOneWidget);
    });

    testWidgets('loading: indicador visível e botão desabilitado', (tester) async {
      client.pendingSignUp = Completer<IResult<int, IFailure>>();
      await tester.pumpWidget(
        _harness(home: const RegisterView(), client: client, store: store),
      );
      await _fillRegister(tester);
      await tester.tap(find.byKey(const Key('register-submit')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byKey(const Key('register-submit'))).onPressed,
        isNull,
      );

      client.pendingSignUp!.complete(const Success(42));
      await tester.pumpAndSettle();
    });
  });

  group('PrivateAreaView — logout (DoD F1.6)', () {
    testWidgets('sair limpa a sessão e volta ao login', (tester) async {
      store.token = 'tok-ativo';
      await tester.pumpWidget(
        _harness(home: const PrivateAreaView(), client: client, store: store),
      );

      await tester.tap(find.byKey(const Key('private-logout')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login-submit')), findsOneWidget);
      expect(store.token, isNull);
      expect(store.clears, 1);
    });
  });
}
