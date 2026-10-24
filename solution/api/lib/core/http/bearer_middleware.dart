import 'package:shelf/shelf.dart';

import '../../modules/auth/ports.dart';
import 'json_response.dart';

/// Chave de contexto para o usuário autenticado na requisição.
const String authenticatedUserKey = 'authenticatedUser';

/// Chave de contexto para o token de sessão na requisição.
const String sessionTokenKey = 'sessionToken';

/// Middleware de autenticação Bearer (INV-SEC-16).
///
/// Exige cabeçalho `Authorization: Bearer <token>` e valida via [ISessionAuthenticator].
/// Não vaza detalhes de usuário no log nem em mensagens de erro.
Middleware bearerMiddleware(ISessionAuthenticator authenticator) {
  return (Handler innerHandler) {
    return (Request request) async {
      final header = request.headers['authorization'] ??
          request.headers['Authorization'];

      if (header == null || !header.startsWith('Bearer ')) {
        return JsonResponse.error(
          401,
          errorCode: 'ERR_NOT_AUTHENTICATED',
          message: 'Sessão ausente ou inválida.',
        );
      }

      final token = header.substring('Bearer '.length).trim();
      if (token.isEmpty) {
        return JsonResponse.error(
          401,
          errorCode: 'ERR_NOT_AUTHENTICATED',
          message: 'Sessão ausente ou inválida.',
        );
      }

      final user = await authenticator.authenticate(token);
      if (user == null) {
        return JsonResponse.error(
          401,
          errorCode: 'ERR_NOT_AUTHENTICATED',
          message: 'Sessão ausente ou inválida.',
        );
      }

      final updatedRequest = request.change(
        context: {
          authenticatedUserKey: user,
          sessionTokenKey: token,
        },
      );

      return innerHandler(updatedRequest);
    };
  };
}

/// Extrai o usuário autenticado do contexto da requisição.
AuthenticatedUser getAuthenticatedUser(Request request) {
  final user = request.context[authenticatedUserKey];
  if (user is! AuthenticatedUser) {
    throw StateError('Requisição sem usuário autenticado no contexto.');
  }
  return user;
}

/// Extrai o token de sessão do contexto da requisição.
String getSessionToken(Request request) {
  final token = request.context[sessionTokenKey];
  if (token is! String) {
    throw StateError('Requisição sem token de sessão no contexto.');
  }
  return token;
}

