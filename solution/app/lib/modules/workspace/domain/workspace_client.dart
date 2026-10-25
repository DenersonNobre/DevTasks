// solution/app/lib/modules/workspace/domain/workspace_client.dart
// Porta de workspaces consumida pela apresentação do app (DIP · ISP).

import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/result.dart';

import 'workspace_item.dart';

abstract interface class IWorkspaceClient {
  Future<IResult<List<WorkspaceItem>, IFailure>> listByUser({
    required String token,
  });

  Future<IResult<WorkspaceItem, IFailure>> create({
    required String name,
    required String token,
  });
}

