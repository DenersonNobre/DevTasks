// Smoke test do pacote do servidor: prova que a identidade do pacote do
// workspace resolve sob o nome novo (UC-00.01 — nenhum pacote se chama mais
// "backend").

import 'package:devtasks_server/devtasks_server.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('devtasks_server exposes the server identity', () {
    expect(serverName, 'devtasks_server');
  });
}
