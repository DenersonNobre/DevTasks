import 'domain/email.dart';
import 'domain/password.dart';
import 'ports.dart';

/// Comando de cadastro — dados crus da fronteira; a normalização é do handler.
class SignUpCommand {
  const SignUpCommand({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;
}

/// Resultado tipado do cadastro: sucesso com o usuário criado ou falha esperada.
class SignUpOutcome {
  const SignUpOutcome._({this.user, this.failure});

  factory SignUpOutcome.success(RegisteredUser user) =>
      SignUpOutcome._(user: user);

  factory SignUpOutcome.failureOf(SignUpFailure failure) =>
      SignUpOutcome._(failure: failure);

  final RegisteredUser? user;
  final SignUpFailure? failure;

  bool get isSuccess => failure == null;
}

/// Regras de cadastro: INV-08 (normalização + unicidade) e política de senha.
///
/// Domínio puro: sem framework, sem I/O, sem relógio — só as portas.
class SignUpHandler {
  SignUpHandler(this._repository, this._hasher);

  final IUserRepository _repository;
  final IPasswordHasher _hasher;

  Future<SignUpOutcome> execute(SignUpCommand command) async {
    final name = command.name.trim();

    if (name.isEmpty) {
      return _validation('Nome é obrigatório.', 'name');
    }
    if (name.length > 100) {
      return _validation('Nome deve ter no máximo 100 caracteres.', 'name');
    }

    final emailResult = Email.parse(command.email);
    if (emailResult.error != null) {
      return _validation(emailResult.error!, 'email');
    }
    final email = emailResult.email!.value;

    final passwordViolation = Password.validate(command.password);
    if (passwordViolation != null) {
      return _validation(passwordViolation, 'password');
    }

    // INV-SEC-04: o hash roda também no caminho de duplicata para não vazar
    // existência de conta por diferença de tempo de resposta.
    final passwordHash = await _hasher.hash(command.password);

    if (await _repository.existsByEmail(email)) {
      return SignUpOutcome.failureOf(
        const SignUpFailure(
          SignUpErrorCode.emailAlreadyTaken,
          'Este e-mail já está em uso.',
          field: 'email',
        ),
      );
    }

    final outcome = await _repository.create(
      name: name,
      email: email,
      passwordHash: passwordHash,
    );

    return switch (outcome) {
      UserCreated(:final user) => SignUpOutcome.success(user),
      EmailTaken() => SignUpOutcome.failureOf(
          const SignUpFailure(
            SignUpErrorCode.emailAlreadyTaken,
            'Este e-mail já está em uso.',
            field: 'email',
          ),
        ),
    };
  }

  SignUpOutcome _validation(String message, String field) =>
      SignUpOutcome.failureOf(
        SignUpFailure(SignUpErrorCode.validation, message, field: field),
      );
}

