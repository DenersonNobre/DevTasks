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
/// Domínio puro: sem framework, sem I/O — só as portas.
class SignInHandler {
  SignInHandler(this._credentials, this._verifier);

  /// Mensagem única para credencial inválida (nunca revela qual campo falhou).
  static const String invalidCredentialsMessage = 'E-mail ou senha inválidos.';

  /// Hash de descarte: garante custo de verificação mesmo sem usuário (timing).
  static const String dummyHash = Argon2PasswordHasher.dummyHash;

  final ICredentialRepository _credentials;
  final IPasswordVerifier _verifier;

  Future<SignInOutcome> execute(SignInCommand command) async {
    final emailResult = Email.parse(command.email);
    if (emailResult.error != null) {
      return _invalidCredentials();
    }

    if (command.password.isEmpty) {
      return _invalidCredentials();
    }

    final normalizedEmail = emailResult.email!.value;
    final record = await _credentials.findByEmail(normalizedEmail);

    final hashToVerify = record?.passwordHash ?? dummyHash;
    final isPasswordValid = await _verifier.verify(
      password: command.password,
      passwordHash: hashToVerify,
    );

    if (record == null || !isPasswordValid) {
      return _invalidCredentials();
    }

    return SignInOutcome.success(
      AuthenticatedUser(id: record.id, email: record.email),
    );
  }

  SignInOutcome _invalidCredentials() => SignInOutcome.failureOf(
        const SignInFailure(
          SignInErrorCode.invalidCredentials,
          invalidCredentialsMessage,
        ),
      );
}
