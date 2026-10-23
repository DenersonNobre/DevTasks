/// Portas do módulo de autenticação (DIP).
///
/// O handler de domínio depende **apenas** destas interfaces; os adaptadores de
/// infraestrutura (persistência/criptografia) ficam na borda do server.
library;

/// Códigos de falha que espelham a taxonomia da `SPEC.md` §6.
///
/// O server é um pacote separado e não importa o kernel da app; a paridade dos
/// códigos (`ERR_VALIDATION`, `ERR_EMAIL_ALREADY_TAKEN`) é o contrato.
enum SignUpErrorCode { validation, emailAlreadyTaken, infra }

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
