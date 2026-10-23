import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../modules/auth/rate_limiter.dart';
import '../modules/auth/sign_in_service.dart';
import '../modules/auth/sign_up_service.dart';

/// Endpoint de autenticação (cadastro e login).
class AuthEndpoint extends Endpoint {
  AuthEndpoint([
    SignUpService? signUpService,
    SignInService? signInService,
    RateLimiter? rateLimiter,
  ])  : _signUpService = signUpService,
        _signInService = signInService,
        _rateLimiter = rateLimiter ?? _defaultRateLimiter;

  static final RateLimiter _defaultRateLimiter =
      InMemoryRateLimiter(now: DateTime.now);

  final SignUpService? _signUpService;
  final SignInService? _signInService;
  final RateLimiter _rateLimiter;

  Future<SignUpResultDto> signUp(Session session, SignUpDto dto) =>
      (_signUpService ?? SignUpService(null, _rateLimiter))
          .signUp(dto, clientIp: _extractClientIp(session));

  Future<SignInResultDto> signIn(Session session, SignInDto dto) =>
      (_signInService ?? SignInService(null, _rateLimiter))
          .signIn(dto, clientIp: _extractClientIp(session));

  /// Extrai o IP do socket da conexão de forma estrita, sem confiar em headers
  /// arbitrários do cliente para mitigar spoofing (INV-SEC-15).
  static String _extractClientIp(Session session) {
    try {
      final address = session.request?.connectionInfo.remote.address;
      if (address != null) {
        return address.toString();
      }
    } catch (e) {
      // Diagnóstico seguro de falha de socket sem registrar o endereço IP (INV-SEC-14).
      session.log('Falha ao obter remote address da conexão: $e',
          level: LogLevel.debug);
    }
    return 'local';
  }
}