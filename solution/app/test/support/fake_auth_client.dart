import 'dart:async';

import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/result.dart';
import 'package:devtasks_app/modules/auth/domain/auth_client.dart';

/// Fake da porta `AuthClient`: configura o resultado, conta chamadas e permite
/// segurar a resposta com [pendingSignIn] para observar o estado de carregamento.
final class FakeAuthClient implements AuthClient {
  IResult<AuthSession, IFailure>? signInResult;
  IResult<String, IFailure>? signUpResult;
  Completer<IResult<AuthSession, IFailure>>? pendingSignIn;
  Completer<IResult<String, IFailure>>? pendingSignUp;

  int signInCalls = 0;
  int signUpCalls = 0;
  int signOutCalls = 0;
  String? lastEmail;
  String? lastPassword;
  String? lastName;
  String? lastToken;
  IResult<void, IFailure>? signOutResult;

  @override
  Future<IResult<void, IFailure>> signOut(String token) {
    signOutCalls++;
    lastToken = token;
    return Future.value(signOutResult ?? const Success(null));
  }

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
  Future<IResult<String, IFailure>> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    signUpCalls++;
    lastName = name;
    lastEmail = email;
    lastPassword = password;

    final pending = pendingSignUp;
    if (pending != null) return pending.future;

    return Future.value(signUpResult ?? Failure(const InfraFailure('sem adaptador')));
  }
}
