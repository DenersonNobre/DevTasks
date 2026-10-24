// solution/app/lib/modules/projects/infrastructure/project_client_provider.dart
// Provider da porta de projetos (composição na borda).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/project_client.dart';
import 'http_project_client.dart';

/// Instancia o adaptador HTTP por padrão; testes sobrescrevem com fake.
final projectClientProvider = Provider<IProjectClient>(
  (_) => HttpProjectClient(),
);
