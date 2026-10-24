import 'package:shelf/shelf.dart';

import 'api_exception.dart';
import 'json_response.dart';

/// Converte falhas em respostas JSON uniformes, sem vazar stack trace.
///
/// SRP: traduzir `ApiException` (esperada) e exceções inesperadas em resposta.
/// NÃO faz: decidir regra de negócio nem logar payload (INV-SEC-05).
Middleware errorMiddleware() {
  return (Handler inner) {
    return (Request request) async {
      try {
        return await inner(request);
      } on ApiException catch (failure) {
        return JsonResponse.error(
          failure.status,
          errorCode: failure.errorCode,
          message: failure.message,
          field: failure.field,
        );
      } on FormatException {
        return JsonResponse.error(
          400,
          errorCode: 'ERR_VALIDATION',
          message: 'Corpo da requisição inválido.',
        );
      } catch (_) {
        // Mensagem genérica: detalhe interno nunca chega ao cliente.
        return JsonResponse.error(
          500,
          errorCode: 'ERR_INFRA_FAILURE',
          message: 'Erro interno ao processar a requisição.',
        );
      }
    };
  };
}
