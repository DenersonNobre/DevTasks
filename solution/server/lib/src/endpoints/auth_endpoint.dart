import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../modules/auth/rate_limiter.dart';
import '../modules/auth/serverpod_session_service.dart';
import '../modules/auth/sign_in_service.dart';
import '../modules/auth/sign_up_service.dart';

/// Endpoint de autenticação (cadastro, login e logout).
class AuthEndpoint extends Endpoint {
  AuthEndpoint([
    SignUpService? signUpService,
    SignInService? signInService,
    RateLimiter? rateLimiter,
    ServerpodSessionService? sessionService,
  ])  : _signUpService = signUpService,
        _signInService = signInService,
        _rateLimiter = rateLimiter ?? _defaultRateLimiter,
        _sessionService = sessionService;

  static final RateLimiter _defaultRateLimiter =
      InMemoryRateLimiter(now: DateTime.now);

  final SignUpService? _signUpService;
  final SignInService? _signInService;
  final RateLimiter _rateLimiter;
  final ServerpodSessionService? _sessionService;

  Future<SignUpResultDto> signUp(Session session, SignUpDto dto) =>
      (_signUpService ?? SignUpService(null, _rateLimiter))
          .signUp(dto, clientIp: _extractClientIp(session));

  Future<SignInResultDto> signIn(Session session, SignInDto dto) {
    final sessionService = _sessionService ??
        ServerpodSessionService(store: ServerpodSessionStore(session));
    return (_signInService ??
            SignInService(null, _rateLimiter, sessionService))
        .signIn(dto, clientIp: _extractClientIp(session));
  }

  /// Revoga a sessão ativa do usuário (INV-SEC-05/06).
  ///
  /// O token pode ser fornecido diretamente ou extraído da requisição.
  /// Operação idempotente que responde com sucesso sem vazar se o token existia.
  Future<SignOutResultDto> signOut(Session session, [String? token]) async {
    final sessionService = _sessionService ??
        ServerpodSessionService(store: ServerpodSessionStore(session));
    final effectiveToken = token ?? _extractToken(session);
    if (effectiveToken == null || effectiveToken.isEmpty) {
      return SignOutResultDto(success: true);
    }
    return sessionService.signOut(effectiveToken);
  }

  /// Extrai o token opaco do header Authorization (`Bearer <token>`).
  static String? _extractToken(Session session) {
    try {
      final authHeader = session.request?.headers['authorization']?.firstOrNull;
      if (authHeader != null && authHeader.toLowerCase().startsWith('bearer ')) {
        return authHeader.substring(7).trim();
      }
    } catch (_) {}
    return null;
  }

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
