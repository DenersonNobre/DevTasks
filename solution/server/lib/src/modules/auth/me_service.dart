import '../../generated/protocol.dart';
import 'session_guard.dart';

/// Serviço do endpoint privado de referência (`me`).
///
/// O token **não** vem do corpo (INV-SEC-06): o endpoint o obtém da sessão/header
/// e passa aqui. Token nulo/vazio/inválido ⇒ `ERR_NOT_AUTHENTICATED`.
class MeService {
  MeService(this._guard);

  final SessionGuard _guard;

  Future<MeResultDto> me(String? token) async {
    final outcome = await _guard.requireSession(token);
    final user = outcome.user;
    if (user != null) {
      return MeResultDto(success: true, userId: user.id, email: user.email);
    }

    return MeResultDto(
      success: false,
      errorCode: outcome.code!.wireCode,
      message: SessionGuard.notAuthenticatedMessage,
    );
  }
}
