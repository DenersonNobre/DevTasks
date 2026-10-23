import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../modules/auth/sign_up_service.dart';

/// Endpoint de cadastro de usuário (F1.1).
class AuthEndpoint extends Endpoint {
  AuthEndpoint([SignUpService? service]) : _service = service;

  final SignUpService? _service;

  Future<SignUpResultDto> signUp(Session session, SignUpDto dto) =>
      (_service ?? SignUpService()).signUp(dto);
}
