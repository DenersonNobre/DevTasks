import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../modules/auth/me_service.dart';
import '../modules/auth/session_guard.dart';

/// Endpoint privado de referência: exige sessão válida (guard de F1.3).
///
/// O token é lido da **sessão/header** (nunca do corpo — INV-SEC-06). Enquanto a
/// emissão de token não existe (follow-up), a leitura devolve `null` e o guard
/// responde `ERR_NOT_AUTHENTICATED` — comportamento correto e **vivo** em produção.
class MeEndpoint extends Endpoint {
  MeEndpoint([MeService? service])
      : _service =
            service ?? MeService(SessionGuard(const NoSessionAuthenticator()));

  final MeService _service;

  Future<MeResultDto> me(Session session) => _service.me(_readToken(session));

  String? _readToken(Session session) {
    // Integração com header/`session.authenticated` do Serverpod: follow-up
    // declarado (o auth module não é usado; emissão de token ainda inexistente).
    return null;
  }
}
