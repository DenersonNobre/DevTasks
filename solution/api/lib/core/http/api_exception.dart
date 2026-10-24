/// Falha esperada da API: vira resposta HTTP com código de erro canônico.
///
/// SRP: carregar status + `errorCode` + mensagem + campo opcional.
/// NÃO faz: logar, serializar ou decidir política de retry.
class ApiException implements Exception {
  const ApiException({
    required this.status,
    required this.errorCode,
    required this.message,
    this.field,
  });

  final int status;
  final String errorCode;
  final String message;
  final String? field;

  const ApiException.badRequest(String message, {String? field})
      : this(
          status: 400,
          errorCode: 'ERR_VALIDATION',
          message: message,
          field: field,
        );

  const ApiException.unauthenticated([String message = 'Sessão ausente ou expirada.'])
      : this(
          status: 401,
          errorCode: 'ERR_NOT_AUTHENTICATED',
          message: message,
        );

  const ApiException.forbidden([String message = 'Permissão insuficiente para esta ação.'])
      : this(
          status: 403,
          errorCode: 'ERR_INSUFFICIENT_ROLE',
          message: message,
        );

  const ApiException.notFound([String message = 'Recurso inexistente ou inacessível.'])
      : this(
          status: 404,
          errorCode: 'ERR_NOT_FOUND',
          message: message,
        );

  const ApiException.conflict(String errorCode, String message)
      : this(status: 409, errorCode: errorCode, message: message);

  const ApiException.rateLimited([String message = 'Muitas tentativas. Tente novamente mais tarde.'])
      : this(
          status: 429,
          errorCode: 'ERR_RATE_LIMITED',
          message: message,
        );

  @override
  String toString() => '$errorCode ($status): $message';
}
