import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_client.dart';
import 'serverpod_auth_client.dart';

/// Provider do adaptador de autenticação [AuthClient].
///
/// Instancia [ServerpodAuthClient] por padrão, podendo receber override em testes.
final authClientProvider = Provider<AuthClient>(
  (_) => ServerpodAuthClient(),
);
