// solution/app/lib/modules/projects/infrastructure/serverpod_project_client.dart
// Adaptador real da porta ProjectClient sobre o client gerado (devtasks_client).
// SRP: traduzir contrato gerado <-> VO/porta do app.
// NÃO faz: validar regra de negócio, guardar token ou decidir navegação.

import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/result.dart';
import 'package:devtasks_app/modules/projects/domain/project_client.dart';
import 'package:devtasks_app/modules/projects/domain/project_summary.dart';
import 'package:devtasks_client/devtasks_client.dart';

/// Fornece o header Bearer estático para as chamadas (INV-SEC-16).
final class _BearerAuthKeyProvider implements ClientAuthKeyProvider {
  const _BearerAuthKeyProvider(this._token);

  final String _token;

  @override
  Future<String?> get authHeaderValue async => wrapAsBearerAuthHeaderValue(_token);
}

/// Implementação de [ProjectClient] conectada ao servidor Serverpod.
///
/// Segurança (Gate 2.5):
/// - Token nunca é logado nem exposto em mensagens (INV-SEC-05);
/// - Token trafega exclusivamente via header Authorization (INV-SEC-16).
class ServerpodProjectClient implements ProjectClient {
  ServerpodProjectClient({String? baseUrl})
      : _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'DEVTASKS_SERVER_URL',
              defaultValue: 'http://localhost:8080/',
            );

  final String _baseUrl;

  @override
  Future<IResult<List<ProjectSummary>, IFailure>> listByWorkspace({
    required int workspaceId,
    required String token,
  }) async {
    final client = _clientFor(token);
    try {
      final result = await client.project.listByWorkspace(workspaceId);
      if (!result.success) return Failure(_failureFrom(result.errorCode, result.message));
      return Success(result.projects.map(_toSummary).toList());
    } catch (_) {
      return const Failure(InfraFailure('Falha de conexão ao carregar projetos.'));
    } finally {
      client.close();
    }
  }

  @override
  Future<IResult<ProjectSummary, IFailure>> create({
    required int workspaceId,
    required String name,
    required String token,
  }) async {
    final client = _clientFor(token);
    try {
      final result = await client.project.create(workspaceId, name);
      return _singleResult(result, 'Falha ao criar projeto.');
    } catch (_) {
      return const Failure(InfraFailure('Falha de conexão ao criar projeto.'));
    } finally {
      client.close();
    }
  }

  @override
  Future<IResult<ProjectSummary, IFailure>> rename({
    required int projectId,
    required String name,
    required String token,
  }) async {
    final client = _clientFor(token);
    try {
      final result = await client.project.update(projectId, name);
      return _singleResult(result, 'Falha ao renomear projeto.');
    } catch (_) {
      return const Failure(InfraFailure('Falha de conexão ao renomear projeto.'));
    } finally {
      client.close();
    }
  }

  Client _clientFor(String token) {
    final client = Client(_baseUrl)..authKeyProvider = _BearerAuthKeyProvider(token);
    return client;
  }

  IResult<ProjectSummary, IFailure> _singleResult(
    ProjectResultDto result,
    String infraMessage,
  ) {
    final project = result.project;
    if (!result.success || project == null) {
      return Failure(_failureFrom(result.errorCode, result.message));
    }
    return Success(_toSummary(project));
  }

  ProjectSummary _toSummary(ProjectDto dto) => ProjectSummary(
        id: dto.id,
        workspaceId: dto.workspaceId,
        name: dto.name,
      );

  IFailure _failureFrom(String? errorCode, String? message) => switch (errorCode) {
        'ERR_VALIDATION' => ValidationFailure(message ?? 'Dados inválidos.', 'name'),
        'ERR_NOT_FOUND' => NotFoundFailure(message ?? 'Projeto ou workspace inacessível.'),
        'ERR_INSUFFICIENT_ROLE' => InsufficientRoleFailure(
            message ?? 'Apenas o owner do workspace pode executar esta ação.',
          ),
        'ERR_NOT_AUTHENTICATED' => NotAuthenticatedFailure(
            message ?? 'Sessão ausente ou expirada.',
          ),
        'ERR_INFRA_FAILURE' => InfraFailure(message ?? 'Falha no servidor de projetos.'),
        _ => InfraFailure(message ?? 'Erro inesperado ao conversar com o servidor.'),
      };
}
