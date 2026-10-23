import 'package:flutter/foundation.dart';

import '../../modules/auth/domain/session_store.dart';

/// Estado de autenticação observável pelo app.
enum SessionStatus { signedOut, authenticated }

/// Retrato imutável da sessão.
@immutable
class SessionState {
  const SessionState({required this.status, this.token});

  const SessionState.signedOut() : this(status: SessionStatus.signedOut);

  final SessionStatus status;
  final String? token;

  bool get isAuthenticated => status == SessionStatus.authenticated;

  /// Token nunca é exposto em texto (INV-SEC-05).
  @override
  String toString() => 'SessionState(${status.name})';
}

/// Controla a sessão do app: restaura no boot e persiste no [SessionStore].
///
/// Puro Flutter (sem I/O direto): a prova de "sobrevive a restart" é um novo
/// controlador lendo o mesmo store injetado.
class SessionController extends ChangeNotifier {
  SessionController(this._store);

  final SessionStore _store;

  SessionState _state = const SessionState.signedOut();

  SessionState get state => _state;

  /// Restaura a sessão salva (chamado no boot).
  Future<void> restore() async {
    final token = await _store.read();
    _set(
      token == null || token.isEmpty
          ? const SessionState.signedOut()
          : SessionState(status: SessionStatus.authenticated, token: token),
    );
  }

  /// Persiste o token e marca a sessão como autenticada.
  Future<void> signIn(String token) async {
    await _store.write(token);
    _set(SessionState(status: SessionStatus.authenticated, token: token));
  }

  /// Limpa a sessão local.
  Future<void> signOut() async {
    await _store.clear();
    _set(const SessionState.signedOut());
  }

  void _set(SessionState next) {
    _state = next;
    notifyListeners();
  }
}
