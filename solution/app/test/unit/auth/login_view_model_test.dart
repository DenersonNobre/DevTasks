import 'dart:async';

import 'package:devtasks_app/global/kernel/.kernel.dart';
import 'package:devtasks_app/global/session/.session.dart';
import 'package:devtasks_app/modules/auth/.auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_client.dart';
import '../../support/in_memory_session_store.dart';

const _validEmail = 'user@example.com';
const _validPassword = 'SenhaForte123';

void main() {
  late FakeAuthClient client;
  late InMemorySessionStore store;
  late ProviderContainer container;

  setUp(() {
    client = FakeAuthClient();
    store = InMemorySessionStore();
    container = ProviderContainer(
      overrides: [
        authClientProvider.overrideWithValue(client),
        sessionStoreProvider.overrideWithValue(store),
      ],
    );
  });

  tearDown(() => container.dispose());

  LoginViewModel viewModel() => container.read(loginViewModelProvider.notifier);
  LoginState readState() => container.read(loginViewModelProvider);

  group('LoginViewModel — validação por VOs (DoD F1.6)', () {
    test('e-mail inválido falha no campo e não chama a porta', () async {
      await viewModel().submit(rawEmail: 'invalido', rawPassword: _validPassword);

      expect(readState().status, AuthFormStatus.idle);
      expect(readState().emailError, 'E-mail inválido.');
      expect(readState().passwordError, isNull);
      expect(client.signInCalls, 0);
    });

    test('senha fora da política falha no campo e não chama a porta', () async {
      await viewModel().submit(rawEmail: _validEmail, rawPassword: 'curta');

      expect(readState().status, AuthFormStatus.idle);
      expect(readState().passwordError, contains('mínimo 12'));
      expect(client.signInCalls, 0);
    });
  });

  group('LoginViewModel — falha e sucesso', () {
    test('credencial inválida vira erro único de formulário', () async {
      client.signInResult = Failure(const InvalidCredentialsFailure());

      await viewModel().submit(rawEmail: _validEmail, rawPassword: _validPassword);

      expect(readState().status, AuthFormStatus.error);
      expect(readState().message, 'E-mail ou senha incorretos.');
      expect(store.token, isNull);
    });

    test('sucesso persiste a sessão e normaliza o e-mail', () async {
      client.signInResult = const Success(AuthSession(userId: 7, token: 'tok-123'));

      await viewModel().submit(rawEmail: '  USER@Example.COM ', rawPassword: _validPassword);

      expect(readState().status, AuthFormStatus.completed);
      expect(store.token, 'tok-123');
      expect(container.read(sessionControllerProvider).state.token, 'tok-123');
      expect(client.lastEmail, _validEmail);
      expect(client.lastPassword, _validPassword);
    });

    test('enquanto a porta responde o estado é loading', () async {
      client.pendingSignIn = Completer<IResult<AuthSession, IFailure>>();

      final pending = viewModel().submit(rawEmail: _validEmail, rawPassword: _validPassword);
      await Future<void>.delayed(Duration.zero);

      expect(readState().status, AuthFormStatus.loading);

      client.pendingSignIn!.complete(const Success(AuthSession(userId: 1, token: 'tok')));
      await pending;

      expect(readState().status, AuthFormStatus.completed);
    });

    test('logout limpa a sessão global (o slice não retém token)', () async {
      client.signInResult = const Success(AuthSession(userId: 7, token: 'tok-123'));
      await viewModel().submit(rawEmail: _validEmail, rawPassword: _validPassword);

      await container.read(sessionControllerProvider).signOut();

      expect(store.token, isNull);
      expect(container.read(sessionControllerProvider).state.isAuthenticated, isFalse);
    });
  });
}
