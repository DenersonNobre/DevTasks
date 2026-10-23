// solution/app/lib/modules/auth/infrastructure/auth_client_provider.dart
// Composição da porta [AuthClient] (DIP): a borda decide o adaptador.
// SRP: expor o provider que a apresentação consome.
// NÃO faz: implementar a chamada — o adaptador Serverpod é follow-up declarado,
// pois a emissão de token ainda não existe no servidor.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_client.dart';

/// Exige override explícito (testes com fake; boot futuro com o cliente gerado).
final authClientProvider = Provider<AuthClient>(
  (_) => throw UnimplementedError(
    'AuthClient não configurado: adaptador Serverpod é follow-up declarado.',
  ),
);
