// solution/app/lib/global/kernel/failures.dart
// Taxonomia canônica de falhas de negócio (SPEC §6 / UC-00.07)

/// Contrato base de falhas de negócio esperadas do sistema.
abstract interface class IFailure {
  String get code;
  String get message;
}

/// Base concreta reutilizável para falhas de domínio.
abstract class BaseFailure implements IFailure {
  @override
  final String code;

  @override
  final String message;

  const BaseFailure({required this.code, required this.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseFailure &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message;

  @override
  int get hashCode => Object.hash(code, message);

  @override
  String toString() => '$code: $message';
}

/// ERR_VALIDATION: Entrada inválida (campos obrigatórios, limites, formatos).
class ValidationFailure extends BaseFailure {
  final String? field;

  const ValidationFailure(String message, [this.field])
      : super(code: 'ERR_VALIDATION', message: message);

  @override
  String toString() =>
      field != null ? 'ERR_VALIDATION ($field): $message' : 'ERR_VALIDATION: $message';
}

/// ERR_NOT_AUTHENTICATED: Sessão ausente, inválida ou expirada (RNF-03).
class NotAuthenticatedFailure extends BaseFailure {
  const NotAuthenticatedFailure([String message = 'Sessão ausente ou expirada.'])
      : super(code: 'ERR_NOT_AUTHENTICATED', message: message);
}

/// ERR_INVALID_CREDENTIALS: E-mail ou senha incorretos (mensagem única, sem enumerar).
class InvalidCredentialsFailure extends BaseFailure {
  const InvalidCredentialsFailure([String message = 'E-mail ou senha incorretos.'])
      : super(code: 'ERR_INVALID_CREDENTIALS', message: message);
}

/// ERR_EMAIL_ALREADY_TAKEN: Cadastro com e-mail já existente (INV-08).
class EmailAlreadyTakenFailure extends BaseFailure {
  const EmailAlreadyTakenFailure([String message = 'Este e-mail já está em uso.'])
      : super(code: 'ERR_EMAIL_ALREADY_TAKEN', message: message);
}

/// ERR_NOT_FOUND: Recurso inexistente ou inacessível ao usuário (INV-01).
class NotFoundFailure extends BaseFailure {
  const NotFoundFailure([String message = 'Recurso inexistente ou inacessível.'])
      : super(code: 'ERR_NOT_FOUND', message: message);
}

/// ERR_INSUFFICIENT_ROLE: Papel mínimo não atingido no workspace (INV-06).
class InsufficientRoleFailure extends BaseFailure {
  const InsufficientRoleFailure([String message = 'Permissão insuficiente para esta ação.'])
      : super(code: 'ERR_INSUFFICIENT_ROLE', message: message);
}

/// ERR_PROJECT_ARCHIVED: Mutação sobre projeto arquivado (INV-05).
class ProjectArchivedFailure extends BaseFailure {
  const ProjectArchivedFailure([String message = 'Projeto arquivado não aceita alterações.'])
      : super(code: 'ERR_PROJECT_ARCHIVED', message: message);
}

/// ERR_INVALID_ASSIGNEE: Atribuição de tarefa a usuário fora do workspace (INV-03).
class InvalidAssigneeFailure extends BaseFailure {
  const InvalidAssigneeFailure([String message = 'Usuário atribuído não pertence ao workspace.'])
      : super(code: 'ERR_INVALID_ASSIGNEE', message: message);
}

/// ERR_MEMBER_ALREADY_EXISTS: Readição de membro existente no workspace (INV-09).
class MemberAlreadyExistsFailure extends BaseFailure {
  const MemberAlreadyExistsFailure([String message = 'Usuário já é membro deste workspace.'])
      : super(code: 'ERR_MEMBER_ALREADY_EXISTS', message: message);
}

/// ERR_CONCURRENT_MODIFICATION: Duas movimentações concorrentes na mesma tarefa (NFR-02).
class ConcurrentModificationFailure extends BaseFailure {
  const ConcurrentModificationFailure([String message = 'Conflito de versão por modificação concorrente.'])
      : super(code: 'ERR_CONCURRENT_MODIFICATION', message: message);
}

/// ERR_INFRA_FAILURE: Falha catastrófica de infraestrutura (banco, timeout, rede).
class InfraFailure extends BaseFailure {
  final Object? cause;

  const InfraFailure(String message, [this.cause])
      : super(code: 'ERR_INFRA_FAILURE', message: message);

  @override
  String toString() => cause != null ? '$code: $message (causa: $cause)' : super.toString();
}

