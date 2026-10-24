// solution/app/lib/modules/auth/infrastructure/auth_client_provider.dart
// Provider da porta de autenticação (composição na borda).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_client.dart';
import 'http_auth_client.dart';

/// Instancia o adaptador HTTP por padrão; testes sobrescrevem com fake.
final authClientProvider = Provider<IAuthClient>(
  (_) => HttpAuthClient(),
);
