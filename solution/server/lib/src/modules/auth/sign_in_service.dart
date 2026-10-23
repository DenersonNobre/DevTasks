import '../../generated/protocol.dart';
import 'ports.dart';
import 'rate_limiter.dart';
import 'serverpod_session_service.dart';
import 'sign_in_handler.dart';

/// Núcleo do login fora do `Endpoint` (testável sem `Session`).
class SignInService {
  SignInService([
    this._handler,
    this._limiter,
    this._sessionService,
  ]);

  final SignInHandler? _handler;
  final RateLimiter? _limiter;
  final ServerpodSessionService? _sessionService;

  Future<SignInResultDto> signIn(SignInDto dto, {String? clientIp}) async {
    // 1. Rate limit roda ANTES de qualquer computação de hash/verify (INV-SEC-13)
    // Política fail-closed: se clientIp for nulo/vazio, chave sentinela 'unknown' é contabilizada.
    if (_limiter != null) {
      final effectiveIp =
          (clientIp != null && clientIp.isNotEmpty) ? clientIp : 'unknown';
      final rateOutcome = _limiter.check('signin:$effectiveIp');
      if (!rateOutcome.isAllowed) {
        return SignInResultDto(
          success: false,
          errorCode: 'ERR_RATE_LIMITED',
          message:
              'Muitas tentativas de autenticação. Tente novamente mais tarde.',
        );
      }
    }

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
      // Emissão do token opaco se o SessionService estiver configurado
      String? sessionToken;
      DateTime? expiresAt;
      if (_sessionService != null) {
        final session = await _sessionService.createSession(userId: user.id);
        sessionToken = session.token;
        expiresAt = session.expiresAt;
      }

      return SignInResultDto(
        success: true,
        userId: user.id,
        sessionToken: sessionToken,
        expiresAt: expiresAt,
      );
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
