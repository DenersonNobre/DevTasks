import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/result.dart';
import 'package:devtasks_app/modules/projects/domain/project_client.dart';
import 'package:devtasks_app/modules/projects/domain/project_summary.dart';

/// UUID determinístico para testes.
String uuid(int n) => '00000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';

/// Fake da porta `ProjectClient`: configura resultados e conta chamadas.
final class FakeProjectClient implements ProjectClient {
  IResult<List<ProjectSummary>, IFailure>? listResult;
  IResult<ProjectSummary, IFailure>? createResult;
  IResult<ProjectSummary, IFailure>? renameResult;

  int listCalls = 0;
  int createCalls = 0;
  int renameCalls = 0;
  String? lastToken;
  String? lastName;
  String? lastWorkspaceId;
  String? lastProjectId;

  @override
  Future<IResult<List<ProjectSummary>, IFailure>> listByWorkspace({
    required String workspaceId,
    required String token,
  }) {
    listCalls++;
    lastWorkspaceId = workspaceId;
    lastToken = token;
    return Future.value(listResult ?? const Success([]));
  }

  @override
  Future<IResult<ProjectSummary, IFailure>> create({
    required String workspaceId,
    required String name,
    required String token,
  }) {
    createCalls++;
    lastWorkspaceId = workspaceId;
    lastName = name;
    lastToken = token;
    return Future.value(
      createResult ??
          Success(ProjectSummary(id: uuid(1), workspaceId: workspaceId, name: name)),
    );
  }

  @override
  Future<IResult<ProjectSummary, IFailure>> rename({
    required String projectId,
    required String name,
    required String token,
  }) {
    renameCalls++;
    lastProjectId = projectId;
    lastName = name;
    lastToken = token;
    return Future.value(
      renameResult ??
          Success(ProjectSummary(id: projectId, workspaceId: uuid(1), name: name)),
    );
  }
}
