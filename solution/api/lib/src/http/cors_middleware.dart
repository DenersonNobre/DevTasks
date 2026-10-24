import 'package:shelf/shelf.dart';

/// CORS para o app Flutter Web e para testes em LAN.
///
/// SRP: responder preflight e adicionar cabeçalhos de liberação.
/// NÃO faz: autenticação nem autorização (isso é do guard de sessão).
Middleware corsMiddleware({String allowedOrigin = '*'}) {
  const allowHeaders = 'Authorization, Content-Type';

  return (Handler inner) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok(null, headers: _headers(allowedOrigin, allowHeaders));
      }

      final response = await inner(request);
      return response.change(headers: _headers(allowedOrigin, allowHeaders));
    };
  };
}

Map<String, String> _headers(String origin, String allowHeaders) => {
      'access-control-allow-origin': origin,
      'access-control-allow-methods': 'GET, POST, PATCH, DELETE, OPTIONS',
      'access-control-allow-headers': allowHeaders,
      'access-control-max-age': '86400',
    };
