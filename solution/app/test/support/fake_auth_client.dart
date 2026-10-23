import 'dart:async';

import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/result.dart';
import 'package:devtasks_app/modules/auth/domain/auth_client.dart';

/// Fake da porta `AuthClient`: configura o resultado, conta chamadas e permite
/// segurar a resposta com [pendingSignIn] para observar o estado de carregamento.
final class FakeAuthClient implements AuthClient {
  IResult<AuthSession, IFailure>? signInResult;
  IResult<int, IFailure>? signUpResult;
  Completer<IResult<AuthSession, IFailure>>? pendingSignIn;

  int signInCalls = 0;
  int signUpCalls = 0;
  String? lastEmail;
  String? lastPassword;
  String? lastName;

  @override
  Future<IResult<AuthSession, IFailure>> signIn({
    required String email,
    required String password,
  }) {
    signInCalls++;
    lastEmail = email;
    lastPassword = password;

    final pending = pendingSignIn;
    if (pending != null) return pending.future;

    return Future.value(signInResult ?? Failure(const InvalidCredentialsFailure()));
  }

  @override
  Future<IResult<int, IFailure>> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    signUpCalls++;
    lastName = name;
    lastEmail = email;
    lastPassword = password;
    return Future.value(signUpResult ?? Failure(const InfraFailure('sem adaptador')));
  }
}
