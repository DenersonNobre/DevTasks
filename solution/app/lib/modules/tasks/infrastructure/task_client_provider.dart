// solution/app/lib/modules/tasks/infrastructure/task_client_provider.dart
// Injeção de dependência da porta ITaskClient via Riverpod.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/task_client.dart';
import 'http_task_client.dart';

/// Provedor da implementação da porta [ITaskClient].
final taskClientProvider = Provider<ITaskClient>((ref) {
  return HttpTaskClient();
});
