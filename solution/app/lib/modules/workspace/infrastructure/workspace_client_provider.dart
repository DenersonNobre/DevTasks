// solution/app/lib/modules/workspace/infrastructure/workspace_client_provider.dart
// Provedor Riverpod da porta IWorkspaceClient (D-03 / D-07).

import 'package:devtasks_app/modules/workspace/domain/workspace_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'http_workspace_client.dart';

final workspaceClientProvider = Provider<IWorkspaceClient>((ref) {
  return HttpWorkspaceClient();
});

