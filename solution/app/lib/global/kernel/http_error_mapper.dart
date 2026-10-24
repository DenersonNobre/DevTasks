// solution/app/lib/global/kernel/http_error_mapper.dart
// Tradução única de `errorCode` do contrato HTTP para falhas tipadas do kernel.
// SRP: mapear código → IFailure. NÃO faz I/O, nem decide retry/navegação.

import 'failures.dart';

/// Mapeia o envelope de erro do contrato (`D-08`) para [IFailure].
///
/// Códigos não previstos caem em [InfraFailure] — nunca em exceção não tratada.
IFailure httpFailureFrom(
  String? errorCode,
  String? message, [
  String? field,
]) {
  return switch (errorCode) {
    'ERR_VALIDATION' => ValidationFailure(
        message ?? 'Dados inválidos.',
        field,
      ),
    'ERR_INVALID_CREDENTIALS' => InvalidCredentialsFailure(
        message ?? 'E-mail ou senha incorretos.',
      ),
    'ERR_EMAIL_ALREADY_TAKEN' => EmailAlreadyTakenFailure(
        message ?? 'Este e-mail já está em uso.',
      ),
    'ERR_RATE_LIMITED' => RateLimitedFailure(
        message ?? 'Muitas tentativas. Tente novamente mais tarde.',
      ),
    'ERR_NOT_AUTHENTICATED' => NotAuthenticatedFailure(
        message ?? 'Sessão ausente ou expirada.',
      ),
    'ERR_NOT_FOUND' => NotFoundFailure(
        message ?? 'Recurso inexistente ou inacessível.',
      ),
    'ERR_INSUFFICIENT_ROLE' => InsufficientRoleFailure(
        message ?? 'Permissão insuficiente para esta ação.',
      ),
    'ERR_PROJECT_ARCHIVED' => ProjectArchivedFailure(
        message ?? 'Projeto arquivado não aceita alterações.',
      ),
    'ERR_CONCURRENT_MODIFICATION' => ConcurrentModificationFailure(
        message ?? 'Conflito de versão por modificação concorrente.',
      ),
    'ERR_INFRA_FAILURE' => InfraFailure(
        message ?? 'Falha no servidor.',
      ),
    _ => InfraFailure(message ?? 'Erro inesperado ao conversar com o servidor.'),
  };
}
