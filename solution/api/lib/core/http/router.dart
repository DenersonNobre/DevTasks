import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../modules/auth/auth_routes.dart';
import '../../modules/workspace/workspace_routes.dart';
import 'api_exception.dart';
import 'cors_middleware.dart';
import 'error_middleware.dart';
import 'json_response.dart';

/// Monta o handler HTTP completo (rotas + middleware).
///
/// SRP: compor router e pipeline. NÃO faz: I/O de rede nem abrir banco —
/// permite que testes invoquem o handler diretamente, sem porta TCP.
///
/// [corsOrigin] deve ser uma allowlist em produção (`*` só em dev).
Handler buildHandler({
  String corsOrigin = '*',
  AuthRoutes? authRoutes,
  WorkspaceRoutes? workspaceRoutes,
}) {
  final router = Router(notFoundHandler: _notFound);
  router.get('/health', _health);
  authRoutes?.register(router);
  workspaceRoutes?.register(router);

  return const Pipeline()
      .addMiddleware(errorMiddleware())
      .addMiddleware(corsMiddleware(allowedOrigin: corsOrigin))
      .addHandler(router.call);
}

Response _health(Request request) => JsonResponse.ok({'status': 'ok'});

Response _notFound(Request request) => JsonResponse.error(
      404,
      errorCode: 'ERR_NOT_FOUND',
      message: 'Rota inexistente.',
    );

/// Exceção usada apenas para provar o middleware de erro em teste.
Never throwForTest(String errorCode) => throw ApiException(
      status: 418,
      errorCode: errorCode,
      message: 'erro de teste',
    );
