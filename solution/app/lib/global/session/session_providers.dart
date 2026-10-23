// solution/app/lib/global/session/session_providers.dart
// Composição do estado transversal de sessão (D-07 regra 4).
// SRP: ligar a porta [SessionStore] ao [SessionController].
// NÃO faz: escolher o mecanismo de armazenamento (adaptador entra pela borda).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_controller.dart';
import 'session_store.dart';

/// O adaptador real (armazenamento local) é injetado na borda do app;
/// enquanto não existir, exige override explícito (testes e boot futuro).
final sessionStoreProvider = Provider<SessionStore>(
  (_) => throw UnimplementedError(
    'SessionStore não configurado: adaptador de armazenamento é follow-up declarado.',
  ),
);

/// Controlador único de sessão do app (observado pelos ViewModels).
final sessionControllerProvider = Provider<SessionController>(
  (ref) => SessionController(ref.watch(sessionStoreProvider)),
);
