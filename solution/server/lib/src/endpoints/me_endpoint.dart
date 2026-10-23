import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../modules/auth/me_service.dart';
import '../modules/auth/serverpod_session_service.dart';
import '../modules/auth/session_guard.dart';

/// Endpoint privado de referência: exige sessão válida (guard de F1.3).
///
/// O token é lido do header `Authorization: Bearer <token>` (nunca do corpo — INV-SEC-06).
/// Com `ServerpodSessionService` conectado, o guard valida o token contra a tabela
/// `devtasks_session` rejeitando tokens expirados ou revogados.
class MeEndpoint extends Endpoint {
  MeEndpoint([MeService? service]) : _service = service;

  final MeService? _service;

  Future<MeResultDto> me(Session session) {
    final service = _service ??
        MeService(
          SessionGuard(
            ServerpodSessionService(store: ServerpodSessionStore(session)),
          ),
        );
    return service.me(_readToken(session));
  }

  String? _readToken(Session session) {
    try {
      final authHeader = session.request?.headers['authorization']?.firstOrNull;
      if (authHeader != null && authHeader.toLowerCase().startsWith('bearer ')) {
        return authHeader.substring(7).trim();
      }
    } catch (_) {}
    return null;
  }
}
