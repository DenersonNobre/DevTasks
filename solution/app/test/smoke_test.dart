// Smoke test do pacote do app: prova que a identidade do pacote do workspace
// resolve sob o nome novo (UC-00.01 — nenhum pacote se chama mais "frontend").

import 'package:devtasks_app/devtasks_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('devtasks_app exposes the app identity', () {
    expect(appName, 'DevTasks');
  });
}
