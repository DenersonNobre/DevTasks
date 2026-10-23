import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/result.dart';
import 'package:devtasks_app/modules/auth/domain/auth_client.dart';
import 'package:devtasks_client/devtasks_client.dart';

/// Adaptador real de [AuthClient] conectado ao servidor Serverpod gerado (`devtasks_client`).
///
/// Aplica Object Calisthenics:
/// - 1 nível de indentação por método;
/// - Early-return;
/// - Mapeamento exaustivo de wire error codes para tipos de [IFailure] do kernel.
///
/// Segurança (Gate 2.5):
/// - Nenhum DTO ou token é logado (INV-SEC-05);
/// - Token trafega exclusivamente via header Authorization (INV-SEC-16).
class ServerpodAuthClient implements AuthClient {
  ServerpodAuthClient({
    Client? client,
    String? baseUrl,
  }) : _client = client ??
            Client(
              baseUrl ??
                  const String.fromEnvironment(
                    'DEVTASKS_SERVER_URL',
                    defaultValue: 'http://localhost:8080/',
                  ),
            );

  final Client _client;

  @override
  Future<IResult<AuthSession, IFailure>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final dto = SignInDto(email: email, password: password);
      final result = await _client.auth.signIn(dto);

      if (result.success && result.sessionToken != null && result.userId != null) {
        final parsedUserId = int.tryParse(result.userId!) ?? 0;
        return Success(
          AuthSession(
            userId: parsedUserId,
            token: result.sessionToken!,
          ),
        );
      }

      final failure = _mapErrorCodeToFailure(
        result.errorCode,
        result.message,
        result.field,
      );
      return Failure(failure);
    } catch (e) {
      return Failure(const InfraFailure('Erro de conexão com o servidor de autenticação.'));
    }
  }

  @override
  Future<IResult<int, IFailure>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final dto = SignUpDto(name: name, email: email, password: password);
      final result = await _client.auth.signUp(dto);

      if (result.success && result.userId != null) {
        final parsedUserId = int.tryParse(result.userId!) ?? 0;
        return Success(parsedUserId);
      }

      final failure = _mapErrorCodeToFailure(
        result.errorCode,
        result.message,
        result.field,
      );
      return Failure(failure);
    } catch (e) {
      return Failure(const InfraFailure('Erro de conexão com o servidor de autenticação.'));
    }
  }

  @override
  Future<IResult<void, IFailure>> signOut(String token) async {
    try {
      final result = await _client.auth.signOut();
      if (result.success) {
        return const Success(null);
      }
      return Failure(
        _mapErrorCodeToFailure(result.errorCode, result.message, null),
      );
    } catch (e) {
      return Failure(const InfraFailure('Erro ao comunicar encerramento de sessão.'));
    }
  }

  /// Mapeia deterministicamente o código de erro retornado pela API para falhas tipadas de domínio.
  static IFailure _mapErrorCodeToFailure(
    String? errorCode,
    String? message,
    String? field,
  ) {
    return switch (errorCode) {
      'ERR_INVALID_CREDENTIALS' => InvalidCredentialsFailure(
          message ?? 'E-mail ou senha incorretos.',
        ),
      'ERR_EMAIL_ALREADY_TAKEN' => EmailAlreadyTakenFailure(
          message ?? 'Este e-mail já está em uso.',
        ),
      'ERR_VALIDATION' => ValidationFailure(
          message ?? 'Dados inválidos.',
          field,
        ),
      'ERR_RATE_LIMITED' => RateLimitedFailure(
          message ?? 'Muitas tentativas. Tente novamente mais tarde.',
        ),
      'ERR_NOT_AUTHENTICATED' => NotAuthenticatedFailure(
          message ?? 'Sessão ausente ou expirada.',
        ),
      _ => InfraFailure(
          message ?? 'Ocorreu um erro no servidor de autenticação.',
        ),
    };
  }
}

