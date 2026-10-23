import 'argon2_password_hasher.dart';
import 'domain/email.dart';
import 'ports.dart';

/// Comando de login (dados crus da fronteira; o handler normaliza o e-mail).
class SignInCommand {
  const SignInCommand({required this.email, required this.password});

  final String email;
  final String password;
}

/// Falha esperada do login.
class SignInFailure {
  const SignInFailure(this.code, this.message, {this.field});

  final SignInErrorCode code;
  final String message;
  final String? field;
}

/// Resultado tipado do login.
class SignInOutcome {
  const SignInOutcome._({this.user, this.failure});

  factory SignInOutcome.success(AuthenticatedUser user) =>
      SignInOutcome._(user: user);

  factory SignInOutcome.failureOf(SignInFailure failure) =>
      SignInOutcome._(failure: failure);

  final AuthenticatedUser? user;
  final SignInFailure? failure;

  bool get isSuccess => failure == null;
}

/// Regras do login (INV-SEC-04: erro único, sem enumerar campo nem e-mail).
///
/// Domínio puro: sem `serverpod`, sem I/O — só as portas.
class SignInHandler {
  SignInHandler(this._credentials, this._verifier);

  /// Mensagem única para credencial inválida (nunca revela qual campo falhou).
  static const String invalidCredentialsMessage = 'E-mail ou senha inválidos.';

  /// Hash de descarte: garante custo de verificação mesmo sem usuário (timing).
  ///
  /// Hash canônico válido com parâmetros OWASP gerado por [Argon2PasswordHasher],
  /// blindando o side-channel de timing (INV-SEC-04).
  static const String dummyHash = Argon2PasswordHasher.dummyHash;

  final CredentialRepository _credentials;
  final PasswordVerifier _verifier;

  Future<SignInOutcome> execute(SignInCommand command) async {
    final email = command.email.trim().toLowerCase();

    if (!Email.isValid(email)) {
      return _validation('E-mail inválido.', 'email');
    }
    if (command.password.isEmpty) {
      return _validation('Senha é obrigatória.', 'password');
    }

    final record = await _credentials.findByEmail(email);

    // A verificação roda SEMPRE — inclusive quando o e-mail não existe — para não
    // vazar existência de conta por diferença de tempo (INV-SEC-04).
    final verified = await _verifier.verify(
      password: command.password,
      passwordHash: record?.passwordHash ?? dummyHash,
    );

    if (record == null || !verified) {
      return SignInOutcome.failureOf(
        const SignInFailure(
          SignInErrorCode.invalidCredentials,
          invalidCredentialsMessage,
        ),
      );
    }

    return SignInOutcome.success(
      AuthenticatedUser(id: record.id, email: record.email),
    );
  }

  SignInOutcome _validation(String message, String field) =>
      SignInOutcome.failureOf(
        SignInFailure(SignInErrorCode.validation, message, field: field),
      );
}
