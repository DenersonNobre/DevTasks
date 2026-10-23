import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../modules/auth/me_service.dart';

/// Endpoint privado de referência: exige sessão válida (guard de F1.3).
class MeEndpoint extends Endpoint {
  MeEndpoint([MeService? service]) : _service = service;

  final MeService? _service;

  Future<MeResultDto> me(Session session, MeDto dto) =>
      (_service ?? MeService()).me(dto);
}
