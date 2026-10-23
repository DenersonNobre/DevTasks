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

/// Porta de persistência de usuários.
abstract interface class UserRepository {
  /// `true` quando já existe usuário com o e-mail **já normalizado**.
  Future<bool> existsByEmail(String normalizedEmail);

  /// Persiste o usuário com `emailVerified = false` e devolve a entidade criada.
  Future<RegisteredUser> create({
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
