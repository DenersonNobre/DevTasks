import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../core/http/bearer_middleware.dart';
import '../../core/http/json_response.dart';
import 'ports.dart';
import 'rate_limiter.dart';
import 'session_service.dart';
import 'sign_in_handler.dart';
import 'sign_up_handler.dart';

/// Rotas HTTP do módulo de autenticação e identidade (D-08 / OpenAPI 3.1).
///
/// Implementa:
/// - `POST /auth/signup` (UC-01.01 / F8.3);
/// - `POST /auth/signin` (UC-01.02 / F8.3 / INV-SEC-04/13/16);
/// - `POST /auth/signout` (UC-01.03 / F8.3 / INV-SEC-16);
/// - `GET /me` (UC-01.05 / F8.3).
class AuthRoutes {
  const AuthRoutes({
    required this.signUpHandler,
    required this.signInHandler,
    required this.sessionService,
    required this.userRepository,
    this.rateLimiter,
  });

  final SignUpHandler signUpHandler;
  final SignInHandler signInHandler;
  final SessionService sessionService;
  final IUserRepository userRepository;
  final IRateLimiter? rateLimiter;

  /// Registra as rotas de auth no roteador do shelf.
  void register(Router router) {
    router.post('/auth/signup', _handleSignUp);
    router.post('/auth/signin', _handleSignIn);

    final protectedPipeline = const Pipeline()
        .addMiddleware(bearerMiddleware(sessionService));

    router.post(
      '/auth/signout',
      protectedPipeline.addHandler(_handleSignOut),
    );
    router.get(
      '/me',
      protectedPipeline.addHandler(_handleMe),
    );
  }

  Future<Response> _handleSignUp(Request request) async {
    final payload = await _readJson(request);
    if (payload == null) {
      return _validationError('Corpo da requisição deve ser um objeto JSON válido.');
    }

    final name = payload['name'];
    final email = payload['email'];
    final password = payload['password'];

    if (name is! String || name.trim().isEmpty) {
      return _validationError('O campo name é obrigatório.', field: 'name');
    }
    if (email is! String || email.trim().isEmpty) {
      return _validationError('O campo email é obrigatório.', field: 'email');
    }
    if (password is! String || password.isEmpty) {
      return _validationError('O campo password é obrigatório.', field: 'password');
    }

    final rateError = _checkRateLimit(request, 'signup:$email');
    if (rateError != null) {
      return rateError;
    }

    final outcome = await signUpHandler.execute(
      SignUpCommand(name: name, email: email, password: password),
    );

    if (!outcome.isSuccess) {
      return _mapSignUpFailure(outcome.failure!);
    }

    return JsonResponse.created({'userId': outcome.user!.id});
  }

  Future<Response> _handleSignIn(Request request) async {
    final payload = await _readJson(request);
    if (payload == null) {
      return _validationError('Corpo da requisição deve ser um objeto JSON válido.');
    }

    final email = payload['email'];
    final password = payload['password'];

    if (email is! String || email.trim().isEmpty) {
      return _validationError('O campo email é obrigatório.', field: 'email');
    }
    if (password is! String || password.isEmpty) {
      return _validationError('O campo password é obrigatório.', field: 'password');
    }

    final rateError = _checkRateLimit(request, 'signin:$email');
    if (rateError != null) {
      return rateError;
    }

    final outcome = await signInHandler.execute(
      SignInCommand(email: email, password: password),
    );

    if (!outcome.isSuccess) {
      return JsonResponse.error(
        401,
        errorCode: 'ERR_INVALID_CREDENTIALS',
        message: 'E-mail ou senha inválidos.',
      );
    }

    final session = await sessionService.createSession(userId: outcome.user!.id);
    return JsonResponse.ok({
      'sessionToken': session.token,
      'userId': outcome.user!.id,
    });
  }

  Future<Response> _handleSignOut(Request request) async {
    final token = getSessionToken(request);
    await sessionService.revokeSession(token);
    return JsonResponse.ok({});
  }

  Future<Response> _handleMe(Request request) async {
    final user = getAuthenticatedUser(request);
    final profile = await userRepository.findById(user.id);
    if (profile == null) {
      return JsonResponse.error(
        401,
        errorCode: 'ERR_NOT_AUTHENTICATED',
        message: 'Sessão ausente ou inválida.',
      );
    }

    return JsonResponse.ok(profile.toJson());
  }

  Response? _checkRateLimit(Request request, String contextKey) {
    final limiter = rateLimiter;
    if (limiter == null) {
      return null;
    }

    final clientIp = _extractClientIp(request);
    final outcome = limiter.check('$clientIp:$contextKey');
    if (outcome.isAllowed) {
      return null;
    }

    final retryAfter = outcome is RateLimited ? outcome.retryAfterSeconds : 60;
    return JsonResponse.error(
      429,
      errorCode: 'ERR_RATE_LIMITED',
      message: 'Muitas tentativas. Tente novamente em instantes.',
      headers: {'Retry-After': retryAfter.toString()},
    );
  }

  Response _mapSignUpFailure(SignUpFailure failure) {
    return switch (failure.code) {
      SignUpErrorCode.validation => JsonResponse.error(
          400,
          errorCode: 'ERR_VALIDATION',
          message: failure.message,
          field: failure.field,
        ),
      SignUpErrorCode.emailAlreadyTaken => JsonResponse.error(
          409,
          errorCode: 'ERR_EMAIL_ALREADY_TAKEN',
          message: failure.message,
          field: failure.field,
        ),
      SignUpErrorCode.infra => JsonResponse.error(
          500,
          errorCode: 'ERR_INFRA_FAILURE',
          message: failure.message,
          field: failure.field,
        ),
    };
  }

  Response _validationError(String message, {String? field}) =>
      JsonResponse.error(
        400,
        errorCode: 'ERR_VALIDATION',
        message: message,
        field: field,
      );

  Future<Map<String, Object?>?> _readJson(Request request) async {
    try {
      final body = await request.readAsString();
      if (body.isEmpty) return null;
      final decoded = jsonDecode(body);
      if (decoded is Map<String, Object?>) return decoded;
      if (decoded is Map) return decoded.cast<String, Object?>();
      return null;
    } catch (_) {
      return null;
    }
  }

  String _extractClientIp(Request request) {
    return request.headers['x-forwarded-for'] ??
        request.headers['x-real-ip'] ??
        'localhost';
  }
}
