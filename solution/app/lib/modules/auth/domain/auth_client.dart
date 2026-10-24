// solution/app/lib/modules/auth/domain/auth_client.dart
// Porta de autenticação do app (DIP) e VO da sessão emitida pelo servidor.
// SRP: declarar o contrato consumido pela apresentação.
// NÃO faz: I/O, HTTP, armazenamento ou conhecimento de framework/servidor.
// Contrato espelha `docs/api/openapi.yaml` (`D-08`): ids são UUID (String).

import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/result.dart';

/// Sessão autenticada emitida pelo servidor.
final class AuthSession {
  const AuthSession({required this.userId, required this.token});

  /// UUID do usuário (contrato `format: uuid`).
  final String userId;
  final String token;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthSession && userId == other.userId && token == other.token;

  @override
  int get hashCode => Object.hash(userId, token);

  /// O token nunca aparece na representação textual (INV-SEC-05).
  @override
  String toString() => 'AuthSession(user: $userId)';
}

/// Contrato de autenticação: falha esperada é valor tipado, não exceção.
abstract interface class IAuthClient {
  Future<IResult<AuthSession, IFailure>> signIn({
    required String email,
    required String password,
  });

  /// Devolve o UUID do usuário criado (o contrato não emite sessão no cadastro).
  Future<IResult<String, IFailure>> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<IResult<void, IFailure>> signOut(String token);
}

/// Alias retrocompatível com a nomenclatura anterior.
typedef AuthClient = IAuthClient;
