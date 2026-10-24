import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/result.dart';
import 'package:devtasks_app/modules/projects/domain/project_client.dart';
import 'package:devtasks_app/modules/projects/domain/project_summary.dart';

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
  int? lastWorkspaceId;
  int? lastProjectId;

  @override
  Future<IResult<List<ProjectSummary>, IFailure>> listByWorkspace({
    required int workspaceId,
    required String token,
  }) {
    listCalls++;
    lastWorkspaceId = workspaceId;
    lastToken = token;
    return Future.value(listResult ?? const Success([]));
  }

  @override
  Future<IResult<ProjectSummary, IFailure>> create({
    required int workspaceId,
    required String name,
    required String token,
  }) {
    createCalls++;
    lastWorkspaceId = workspaceId;
    lastName = name;
    lastToken = token;
    return Future.value(
      createResult ??
          Success(ProjectSummary(id: 1, workspaceId: workspaceId, name: name)),
    );
  }

  @override
  Future<IResult<ProjectSummary, IFailure>> rename({
    required int projectId,
    required String name,
    required String token,
  }) {
    renameCalls++;
    lastProjectId = projectId;
    lastName = name;
    lastToken = token;
    return Future.value(
      renameResult ??
          Success(ProjectSummary(id: projectId, workspaceId: 1, name: name)),
    );
  }
}
