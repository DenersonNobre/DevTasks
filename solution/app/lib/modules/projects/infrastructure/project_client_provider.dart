// solution/app/lib/modules/projects/infrastructure/project_client_provider.dart
// Provider da porta de projetos (composição na borda).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/project_client.dart';
import 'serverpod_project_client.dart';

/// Instancia [ServerpodProjectClient] por padrão; testes sobrescrevem com fake.
final projectClientProvider = Provider<ProjectClient>(
  (_) => ServerpodProjectClient(),
);
