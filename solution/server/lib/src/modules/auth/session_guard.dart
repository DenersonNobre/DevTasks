import 'ports.dart';

/// Códigos do guard de sessão (espelham a `SPEC.md` §6).
enum SessionGuardErrorCode {
  notAuthenticated('ERR_NOT_AUTHENTICATED'),
  infra('ERR_INFRA_FAILURE');

  const SessionGuardErrorCode(this.wireCode);

  final String wireCode;
}

/// Resultado do guard: usuário autorizado ou código de falha.
class GuardOutcome {
  const GuardOutcome._({this.user, this.code});

  factory GuardOutcome.success(AuthenticatedUser user) =>
      GuardOutcome._(user: user);

  factory GuardOutcome.failure(SessionGuardErrorCode code) =>
      GuardOutcome._(code: code);

  final AuthenticatedUser? user;
  final SessionGuardErrorCode? code;

  bool get isAuthorized => user != null;
}

/// Guard de sessão para endpoints privados.
///
/// Padrão de referência: todo endpoint privado (EPIC-02+) exige sessão válida
/// e falha com `ERR_NOT_AUTHENTICATED` — contrato de servidor, não de UI.
class SessionGuard {
  SessionGuard(this._authenticator);

  static const String notAuthenticatedMessage = 'Sessão ausente ou inválida.';

  final SessionAuthenticator _authenticator;

  Future<GuardOutcome> requireSession(String? token) async {
    if (token == null || token.isEmpty) {
      return GuardOutcome.failure(SessionGuardErrorCode.notAuthenticated);
    }

    final user = await _authenticator.authenticate(token);
    if (user == null) {
      return GuardOutcome.failure(SessionGuardErrorCode.notAuthenticated);
    }

    return GuardOutcome.success(user);
  }
}
