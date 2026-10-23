import 'package:devtasks_app/global/kernel/.kernel.dart';
import 'package:devtasks_app/global/session/.session.dart';
import 'package:devtasks_app/modules/auth/.auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_client.dart';
import '../../support/in_memory_session_store.dart';

const _validName = 'Ana Silva';
const _validEmail = 'ana@example.com';
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

  RegisterViewModel viewModel() => container.read(registerViewModelProvider.notifier);
  RegisterState readState() => container.read(registerViewModelProvider);

  group('RegisterViewModel — validação por VOs (DoD F1.6)', () {
    test('nome vazio falha no campo e não chama a porta', () async {
      await viewModel().submit(
        rawName: '   ',
        rawEmail: _validEmail,
        rawPassword: _validPassword,
      );

      expect(readState().status, AuthFormStatus.idle);
      expect(readState().nameError, 'nome não pode ser vazio.');
      expect(client.signUpCalls, 0);
    });

    test('e-mail inválido falha no campo e não chama a porta', () async {
      await viewModel().submit(
        rawName: _validName,
        rawEmail: 'sem-arroba',
        rawPassword: _validPassword,
      );

      expect(readState().emailError, 'E-mail inválido.');
      expect(client.signUpCalls, 0);
    });

    test('senha fora da política falha no campo e não chama a porta', () async {
      await viewModel().submit(
        rawName: _validName,
        rawEmail: _validEmail,
        rawPassword: 'curta',
      );

      expect(readState().passwordError, contains('mínimo 12'));
      expect(client.signUpCalls, 0);
    });
  });

  group('RegisterViewModel — falha e sucesso', () {
    test('e-mail já cadastrado vira erro único de formulário', () async {
      client.signUpResult = Failure(const EmailAlreadyTakenFailure());

      await viewModel().submit(
        rawName: _validName,
        rawEmail: _validEmail,
        rawPassword: _validPassword,
      );

      expect(readState().status, AuthFormStatus.error);
      expect(readState().message, 'Este e-mail já está em uso.');
      expect(readState().userId, isNull);
    });

    test('sucesso conclui com userId e não cria sessão (contrato sem token)', () async {
      client.signUpResult = const Success(42);

      await viewModel().submit(
        rawName: '  Ana Silva ',
        rawEmail: ' ANA@Example.COM ',
        rawPassword: _validPassword,
      );

      expect(readState().status, AuthFormStatus.completed);
      expect(readState().userId, 42);
      expect(store.token, isNull);
      expect(client.lastName, _validName);
      expect(client.lastEmail, _validEmail);
    });
  });
}
