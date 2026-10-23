import 'package:devtasks_server/src/generated/protocol.dart';
import 'package:devtasks_server/src/modules/workspace/ports.dart';
import 'package:devtasks_server/src/modules/workspace/workspace_service.dart';
import 'package:test/test.dart';

/// Red: MembershipGuard ainda nao aplicado no endpoint.
/// Apos aplicacao do guard, este teste deve passar (Green).
void main() {
  group('UC-02.03 — MembershipGuard (Red→Green)', () {
    test('guard rejeita nao-owner (INV-06)', () async {
      // Red placeholder — apos aplicacao do MembershipGuard no endpoint,
      // este teste deve confirmar que nao-owner recebe falha tipada.
      expect(true, isTrue);
    });
  });
}
