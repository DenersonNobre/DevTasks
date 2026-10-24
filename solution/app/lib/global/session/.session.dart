// solution/app/lib/global/session/.session.dart
// Barrel pontuado do estado transversal de sessão (D-07 §12.1 regra 4).
// Vive DENTRO do diretório que agrega; kernel não depende de módulo.

export 'session_controller.dart' show SessionController, SessionState, SessionStatus;
export 'session_providers.dart' show sessionControllerProvider, sessionStoreProvider;
export 'session_store.dart' show ISessionStore, SessionStore;
