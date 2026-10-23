import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../modules/auth/ports.dart';
import '../modules/auth/sign_up_handler.dart';

/// Endpoint de cadastro (F1.1 / UC-01.01).
///
/// Borda fina: a regra vive em [SignUpHandler] (domínio puro). Os adaptadores de
/// persistência e de hash entram por injeção — sem eles o endpoint responde
/// `ERR_INFRA_FAILURE` em vez de fingir sucesso (capacidade declarada, não fingida).
class AuthEndpoint extends Endpoint {
  AuthEndpoint([this._handler]);

  final SignUpHandler? _handler;

  Future<SignUpResultDto> signUp(Session session, SignUpDto dto) async {
    final handler = _handler;
    if (handler == null) {
      return SignUpResultDto(
        success: false,
        errorCode: 'ERR_INFRA_FAILURE',
        message: 'Adaptadores de persistência/hash não provisionados.',
      );
    }

    final outcome = await handler.execute(
      SignUpCommand(name: dto.name, email: dto.email, password: dto.password),
    );

    final user = outcome.user;
    if (user != null) {
      return SignUpResultDto(success: true, userId: user.id);
    }

    final failure = outcome.failure!;
    return SignUpResultDto(
      success: false,
      errorCode: _errorCodeFor(failure.code),
      message: failure.message,
    );
  }

  static String _errorCodeFor(SignUpErrorCode code) => switch (code) {
        SignUpErrorCode.validation => 'ERR_VALIDATION',
        SignUpErrorCode.emailAlreadyTaken => 'ERR_EMAIL_ALREADY_TAKEN',
        SignUpErrorCode.infra => 'ERR_INFRA_FAILURE',
      };
}
