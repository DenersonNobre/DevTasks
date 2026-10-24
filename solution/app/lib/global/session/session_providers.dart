import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'flutter_secure_key_value_store.dart';
import 'secure_session_store.dart';
import 'session_controller.dart';
import 'session_store.dart';

/// Provider da porta fina de chave-valor segura.
final secureKeyValueStoreProvider = Provider<ISecureKeyValueStore>(
  (_) => const FlutterSecureKeyValueStore(),
);

/// Provider do adaptador de persistência de sessão.
final sessionStoreProvider = Provider<ISessionStore>(
  (ref) => SecureSessionStore(ref.watch(secureKeyValueStoreProvider)),
);

/// Controlador único de sessão do app (observado pelos ViewModels).
final sessionControllerProvider = ChangeNotifierProvider<SessionController>(
  (ref) => SessionController(ref.watch(sessionStoreProvider)),
);
