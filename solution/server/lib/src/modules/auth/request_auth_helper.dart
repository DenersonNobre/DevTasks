import 'package:serverpod/serverpod.dart';

/// Utilitários de segurança para extração de credenciais de requisição HTTP (Gate 2.5).
abstract final class RequestAuthHelper {
  /// Extrai de forma estrita o token Bearer do cabeçalho `Authorization` (INV-SEC-16).
  ///
  /// Usa [RequestExtension.getAuthorizationHeaderValue] do Serverpod / Relic.
  /// Retorna `null` se ausente, malformado ou vazio. Nunca lança exceção.
  static String? extractBearerToken(Session session) {
    try {
      final request = session.request;
      if (request == null) {
        return null;
      }

      final headerValue = request.getAuthorizationHeaderValue(false);
      if (headerValue == null) {
        return null;
      }

      final trimmed = headerValue.trim();
      if (trimmed.length > 7 &&
          trimmed.substring(0, 7).toLowerCase() == 'bearer ') {
        final token = trimmed.substring(7).trim();
        return token.isNotEmpty ? token : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
