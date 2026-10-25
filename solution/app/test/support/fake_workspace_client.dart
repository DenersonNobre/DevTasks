// solution/app/test/support/fake_workspace_client.dart
// Fake em memória de IWorkspaceClient para testes.

import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/result.dart';
import 'package:devtasks_app/modules/workspace/domain/workspace_client.dart';
import 'package:devtasks_app/modules/workspace/domain/workspace_item.dart';

class FakeWorkspaceClient implements IWorkspaceClient {
  final List<WorkspaceItem> workspaces = [];
  bool shouldFail = false;
  IFailure failureToReturn = const InfraFailure('Erro simulado');

  @override
  Future<IResult<List<WorkspaceItem>, IFailure>> listByUser({
    required String token,
  }) async {
    if (shouldFail) return Failure(failureToReturn);
    return Success(List.unmodifiable(workspaces));
  }

  @override
  Future<IResult<WorkspaceItem, IFailure>> create({
    required String name,
    required String token,
  }) async {
    if (shouldFail) return Failure(failureToReturn);
    if (name.trim().isEmpty) {
      return const Failure(ValidationFailure('Nome inválido'));
    }
    final item = WorkspaceItem(
      id: 'ws-${workspaces.length + 1}',
      name: name.trim(),
      role: 'owner',
      createdAt: DateTime.now().toUtc(),
    );
    workspaces.add(item);
    return Success(item);
  }
}

