import '../../generated/protocol.dart';
import 'session_guard.dart';

/// Serviço do endpoint privado de referência (`me`).
class MeService {
  MeService([this._guard]);

  final SessionGuard? _guard;

  Future<MeResultDto> me(MeDto dto) async {
    final guard = _guard;
    if (guard == null) {
      return MeResultDto(
        success: false,
        errorCode: SessionGuardErrorCode.infra.wireCode,
        message: 'Indisponível no momento.',
      );
    }

    final outcome = await guard.requireSession(dto.token);
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
