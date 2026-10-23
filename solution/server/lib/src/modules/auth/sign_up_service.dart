import '../../generated/protocol.dart';
import 'ports.dart';
import 'rate_limiter.dart';
import 'sign_up_handler.dart';

/// Núcleo do cadastro fora do `Endpoint` (testável sem `Session`).
class SignUpService {
  SignUpService([this._handler, this._limiter]);

  final SignUpHandler? _handler;
  final RateLimiter? _limiter;

  Future<SignUpResultDto> signUp(SignUpDto dto, {String? clientIp}) async {
    // 1. Rate limit roda ANTES de qualquer computação de senha/hash (INV-SEC-12)
    if (_limiter != null && clientIp != null && clientIp.isNotEmpty) {
      final rateOutcome = _limiter.check('signup:$clientIp');
      if (!rateOutcome.isAllowed) {
        return SignUpResultDto(
          success: false,
          errorCode: 'ERR_RATE_LIMITED',
          message: 'Muitas tentativas de cadastro. Tente novamente mais tarde.',
        );
      }
    }

    final handler = _handler;
    if (handler == null) {
      return SignUpResultDto(
        success: false,
        errorCode: SignUpErrorCode.infra.wireCode,
        message: 'Cadastro indisponível no momento.',
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
      errorCode: failure.code.wireCode,
      message: failure.message,
      field: failure.field,
    );
  }
}
