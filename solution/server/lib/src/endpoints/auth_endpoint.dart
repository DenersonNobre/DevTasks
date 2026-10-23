import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../modules/auth/argon2_password_hasher.dart';
import '../modules/auth/rate_limiter.dart';
import '../modules/auth/request_auth_helper.dart';
import '../modules/auth/serverpod_session_repository.dart';
import '../modules/auth/serverpod_session_service.dart';
import '../modules/auth/serverpod_user_repository.dart';
import '../modules/auth/sign_in_handler.dart';
import '../modules/auth/sign_in_service.dart';
import '../modules/auth/sign_up_handler.dart';
import '../modules/auth/sign_up_service.dart';

/// Endpoint de autenticação (cadastro, login e logout).
///
/// Aplica Object Calisthenics:
/// - 1 nível de indentação por método;
/// - Early-return;
/// - Sem argumentos de token no corpo do signOut (INV-SEC-16).
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

  Future<SignUpResultDto> signUp(Session session, SignUpDto dto) {
    final service = _signUpService ?? _buildSignUpService(session);
    return service.signUp(dto, clientIp: _extractClientIp(session));
  }

  Future<SignInResultDto> signIn(Session session, SignInDto dto) {
    final service = _signInService ?? _buildSignInService(session);
    return service.signIn(dto, clientIp: _extractClientIp(session));
  }

  /// Revoga a sessão ativa do usuário baseando-se estritamente no header `Authorization: Bearer` (INV-SEC-16).
  ///
  /// Proibido aceitar token no corpo do RPC para mitigar vazamento e fixação de sessão.
  /// Operação idempotente que responde com sucesso sem revelar estado.
  Future<SignOutResultDto> signOut(Session session) async {
    final token = RequestAuthHelper.extractBearerToken(session);
    if (token == null) {
      return SignOutResultDto(success: true);
    }

    final service = _sessionService ?? _buildSessionService(session);
    await service.revokeSession(token);
    return SignOutResultDto(success: true);
  }

  SignUpService _buildSignUpService(Session session) {
    final userRepo = ServerpodUserRepository(session);
    const hasher = Argon2PasswordHasher();
    final handler = SignUpHandler(userRepo, hasher);
    return SignUpService(handler, _rateLimiter);
  }

  SignInService _buildSignInService(Session session) {
    final userRepo = ServerpodUserRepository(session);
    const verifier = Argon2PasswordHasher();
    final handler = SignInHandler(userRepo, verifier);
    final sessionService = _sessionService ?? _buildSessionService(session);
    return SignInService(handler, _rateLimiter, sessionService);
  }

  ServerpodSessionService _buildSessionService(Session session) {
    final sessionRepo = ServerpodSessionRepository(session);
    final credRepo = ServerpodUserRepository(session);
    return ServerpodSessionService(
      repository: sessionRepo,
      credentialRepository: credRepo,
    );
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
      session.log('Falha ao obter remote address da conexão: $e',
          level: LogLevel.debug);
    }
    return 'local';
  }
}
