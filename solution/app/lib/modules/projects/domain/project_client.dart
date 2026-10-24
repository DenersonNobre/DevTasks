// solution/app/lib/modules/projects/domain/project_client.dart
// Porta de projetos consumida pela apresentação (DIP).
// SRP: declarar o contrato. NÃO faz: I/O, HTTP, armazenamento ou serialização.
// IDs são UUID (`String`) — contrato OpenAPI (`D-08`).

import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/result.dart';

import 'project_summary.dart';

/// Contrato de projetos do app: falha esperada é valor tipado, não exceção.
///
/// O `token` é explícito porque a sessão é estado transversal (`global/session/`),
/// nunca responsabilidade do slice (INV-SEC-16: header Bearer).
abstract interface class IProjectClient {
  Future<IResult<List<ProjectSummary>, IFailure>> listByWorkspace({
    required String workspaceId,
    required String token,
  });

  Future<IResult<ProjectSummary, IFailure>> create({
    required String workspaceId,
    required String name,
    required String token,
  });

  Future<IResult<ProjectSummary, IFailure>> rename({
    required String projectId,
    required String name,
    required String token,
  });
}

/// Alias retrocompatível com a nomenclatura anterior.
typedef ProjectClient = IProjectClient;
