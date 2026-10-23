import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../modules/auth/me_service.dart';
import '../modules/auth/request_auth_helper.dart';
import '../modules/auth/serverpod_session_repository.dart';
import '../modules/auth/serverpod_session_service.dart';
import '../modules/auth/serverpod_user_repository.dart';
import '../modules/auth/session_guard.dart';

/// Endpoint privado de referência: exige sessão válida (guard de F1.3).
///
/// O token é lido exclusivamente do header `Authorization: Bearer <token>` (INV-SEC-16).
/// Com `ServerpodSessionService` conectado, o guard valida o token contra a tabela
/// `devtasks_session` rejeitando tokens expirados ou revogados.
class MeEndpoint extends Endpoint {
  MeEndpoint([MeService? service]) : _service = service;

  final MeService? _service;

  Future<MeResultDto> me(Session session) {
    final service = _service ?? _buildMeService(session);
    final token = RequestAuthHelper.extractBearerToken(session);
    return service.me(token);
  }

  MeService _buildMeService(Session session) {
    final sessionRepo = ServerpodSessionRepository(session);
    final credRepo = ServerpodUserRepository(session);
    final sessionService = ServerpodSessionService(
      repository: sessionRepo,
      credentialRepository: credRepo,
    );
    final guard = SessionGuard(sessionService);
    return MeService(guard);
  }
}
