import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../modules/auth/sign_in_service.dart';
import '../modules/auth/sign_up_service.dart';

/// Endpoint de autenticação (cadastro e login).
class AuthEndpoint extends Endpoint {
  AuthEndpoint([SignUpService? signUpService, SignInService? signInService])
      : _signUpService = signUpService,
        _signInService = signInService;

  final SignUpService? _signUpService;
  final SignInService? _signInService;

  Future<SignUpResultDto> signUp(Session session, SignUpDto dto) =>
      (_signUpService ?? SignUpService()).signUp(dto);

  Future<SignInResultDto> signIn(Session session, SignInDto dto) =>
      (_signInService ?? SignInService()).signIn(dto);
}
