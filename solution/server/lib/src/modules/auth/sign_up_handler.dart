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
/// Domínio puro: sem `serverpod`, sem I/O, sem relógio — só as portas.
class SignUpHandler {
  SignUpHandler(this._repository, this._hasher);

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _lower = RegExp('[a-z]');
  static final RegExp _upper = RegExp('[A-Z]');
  static final RegExp _digit = RegExp('[0-9]');

  static const int minPasswordLength = 12;
  static const int maxPasswordLength = 128;

  final UserRepository _repository;
  final PasswordHasher _hasher;

  Future<SignUpOutcome> execute(SignUpCommand command) async {
    final email = command.email.trim().toLowerCase();

    if (email.isEmpty) {
      return _validation('E-mail é obrigatório.', 'email');
    }
    if (!_emailPattern.hasMatch(email)) {
      return _validation('E-mail inválido.', 'email');
    }

    final passwordViolation = _passwordViolation(command.password);
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

    final user = await _repository.create(
      name: command.name.trim(),
      email: email,
      passwordHash: passwordHash,
    );
    return SignUpOutcome.success(user);
  }

  SignUpOutcome _validation(String message, String field) =>
      SignUpOutcome.failureOf(
        SignUpFailure(SignUpErrorCode.validation, message, field: field),
      );

  String? _passwordViolation(String password) {
    if (password.length < minPasswordLength) {
      return 'A senha deve ter ao menos $minPasswordLength caracteres.';
    }
    if (password.length > maxPasswordLength) {
      return 'A senha deve ter no máximo $maxPasswordLength caracteres.';
    }
    if (!_lower.hasMatch(password)) {
      return 'A senha deve conter ao menos uma letra minúscula.';
    }
    if (!_upper.hasMatch(password)) {
      return 'A senha deve conter ao menos uma letra maiúscula.';
    }
    if (!_digit.hasMatch(password)) {
      return 'A senha deve conter ao menos um dígito.';
    }
    return null;
  }
}
