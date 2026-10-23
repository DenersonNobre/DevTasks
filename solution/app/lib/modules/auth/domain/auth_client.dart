// solution/app/lib/modules/auth/domain/auth_client.dart
// Porta de autenticação do app (DIP) e VO da sessão emitida pelo servidor.
// SRP: declarar o contrato consumido pela apresentação.
// NÃO faz: I/O, HTTP, armazenamento ou conhecimento do Serverpod.
// Contrato espelha `SignInResultDto`/`SignUpResultDto` (client gerado 3.4.13):
// `signIn` devolve token; `signUp` devolve o id (o contrato não emite sessão).

import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/result.dart';

/// Sessão autenticada emitida pelo servidor.
final class AuthSession {
  const AuthSession({required this.userId, required this.token});

  final int userId;
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
abstract interface class AuthClient {
  Future<IResult<AuthSession, IFailure>> signIn({
    required String email,
    required String password,
  });

  Future<IResult<int, IFailure>> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<IResult<void, IFailure>> signOut(String token);
}
