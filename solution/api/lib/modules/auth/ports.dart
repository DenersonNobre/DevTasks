/// Portas do módulo de autenticação (DIP).
///
/// O handler de domínio depende **apenas** destas interfaces; os adaptadores de
/// infraestrutura (persistência/criptografia) ficam na borda do server.
library;

/// Códigos de falha que espelham a taxonomia da `SPEC.md` §6.
///
/// O server é um pacote separado e não importa o kernel da app; a paridade dos
/// códigos (`ERR_VALIDATION`, `ERR_EMAIL_ALREADY_TAKEN`, `ERR_INFRA_FAILURE`) é o contrato.
enum SignUpErrorCode {
  validation('ERR_VALIDATION'),
  emailAlreadyTaken('ERR_EMAIL_ALREADY_TAKEN'),
  infra('ERR_INFRA_FAILURE');

  const SignUpErrorCode(this.wireCode);

  /// Código estável exposto no contrato (fonte única — sem strings duplicadas).
  final String wireCode;
}

/// Falha esperada de negócio do cadastro (nunca exceção para fluxo esperado).
class SignUpFailure {
  const SignUpFailure(this.code, this.message, {this.field});

  final SignUpErrorCode code;
  final String message;
  final String? field;
}

/// Usuário persistido que o cadastro devolve.
class RegisteredUser {
  const RegisteredUser({
    required this.id,
    required this.name,
    required this.email,
    required this.emailVerified,
  });

  final String id;
  final String name;
  final String email;
  final bool emailVerified;
}

/// Resultado tipado da criação de usuário (falha esperada é valor, não exceção).
sealed class CreateUserOutcome {
  const CreateUserOutcome();
}

/// Usuário criado e persistido com sucesso.
final class UserCreated extends CreateUserOutcome {
  const UserCreated(this.user);
  final RegisteredUser user;
}

/// Conflito de unicidade de e-mail (TOCTOU mitigado na persistência).
final class EmailTaken extends CreateUserOutcome {
  const EmailTaken();
}

/// Porta de persistência de usuários.
abstract interface class UserRepository {
  /// `true` quando já existe usuário com o e-mail **já normalizado**.
  Future<bool> existsByEmail(String normalizedEmail);

  /// Persiste o usuário com `emailVerified = false` e devolve o resultado tipado.
  Future<CreateUserOutcome> create({
    required String name,
    required String email,
    required String passwordHash,
  });
}

/// Porta de criptografia: a senha só cruza a fronteira já como hash.
abstract interface class PasswordHasher {
  Future<String> hash(String password);
}

/// Registro mínimo para autenticar — inclui o hash; **só esta porta o expõe** (ISP).
class CredentialRecord {
  const CredentialRecord({
    required this.id,
    required this.email,
    required this.passwordHash,
  });

  final String id;
  final String email;
  final String passwordHash;
}

/// Porta de leitura de credenciais (o handler de cadastro não depende do hash).
abstract interface class CredentialRepository {
  Future<CredentialRecord?> findByEmail(String normalizedEmail);
  Future<String?> findEmailById(String userId);
}

/// Porta de verificação de senha contra um hash armazenado.
abstract interface class PasswordVerifier {
  Future<bool> verify({required String password, required String passwordHash});
}

/// Usuário autenticado devolvido pelo login.
class AuthenticatedUser {
  const AuthenticatedUser({required this.id, required this.email});

  final String id;
  final String email;
}

/// Códigos de falha do login (espelham a `SPEC.md` §6).
enum SignInErrorCode {
  invalidCredentials('ERR_INVALID_CREDENTIALS'),
  validation('ERR_VALIDATION'),
  infra('ERR_INFRA_FAILURE');

  const SignInErrorCode(this.wireCode);

  final String wireCode;
}

/// Porta de validação de sessão (token → usuário autenticado | `null`).
abstract interface class SessionAuthenticator {
  Future<AuthenticatedUser?> authenticate(String token);
}

/// Registro imutável de sessão para persistência (INV-SEC-10/17).
class SessionRecord {
  const SessionRecord({
    required this.userId,
    required this.tokenHash,
    required this.createdAt,
    required this.expiresAt,
    this.revokedAt,
  });

  final String userId;
  final String tokenHash;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? revokedAt;

  bool isExpired(DateTime now) => !now.isBefore(expiresAt);
  bool get isRevoked => revokedAt != null;
}

/// Abstração de persistência para registros de sessão (DIP/ISP).
abstract interface class SessionRepository {
  Future<void> save(SessionRecord session);
  Future<SessionRecord?> findByTokenHash(String tokenHash);
  Future<void> revokeByTokenHash(String tokenHash, DateTime revokedAt);
}

