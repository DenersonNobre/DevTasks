import '../../generated/protocol.dart';
import 'ports.dart';
import 'rate_limiter.dart';
import 'sign_in_handler.dart';

/// Núcleo do login fora do `Endpoint` (testável sem `Session`).
class SignInService {
  SignInService([this._handler, this._limiter]);

  final SignInHandler? _handler;
  final RateLimiter? _limiter;

  Future<SignInResultDto> signIn(SignInDto dto, {String? clientIp}) async {
    final handler = _handler;
    if (handler == null) {
      return SignInResultDto(
        success: false,
        errorCode: SignInErrorCode.infra.wireCode,
        message: 'Login indisponível no momento.',
      );
    }

    final outcome = await handler.execute(
      SignInCommand(email: dto.email, password: dto.password),
    );

    final user = outcome.user;
    if (user != null) {
      // Emissão real de sessão (token opaco, header-only) é do adapter/IDP — follow-up.
      return SignInResultDto(success: true, userId: user.id);
    }

    final failure = outcome.failure!;
    return SignInResultDto(
      success: false,
      errorCode: failure.code.wireCode,
      message: failure.message,
      field: failure.field,
    );
  }
}
