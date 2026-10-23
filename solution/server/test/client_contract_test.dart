// Guarda de infraestrutura do contrato gerado (UC-01.00 / TASK-02).
//
// O `solution/client` é o contrato client↔server gerado por `serverpod generate`.
// Ele precisa existir, integrar o pub workspace e NÃO ser ignorado pelo Git:
// um membro de workspace ausente quebra `flutter pub get` em clone limpo.

import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('solution/client é gerado e integra o pub workspace', () {
    final clientPubspec = File('../client/pubspec.yaml');

    expect(
      clientPubspec.existsSync(),
      isTrue,
      reason: 'solution/client ausente — rode `serverpod generate` em solution/server',
    );

    final pubspec = clientPubspec.readAsStringSync();
    expect(pubspec, contains('name: devtasks_client'));
    expect(pubspec, contains('resolution: workspace'));
    expect(
      File('../client/lib/devtasks_client.dart').existsSync(),
      isTrue,
      reason: 'entrypoint do client gerado ausente',
    );
  });

  test('o client gerado é versionável (workspace + não ignorado)', () {
    final rootPubspec = File('../../pubspec.yaml').readAsStringSync();
    expect(
      rootPubspec,
      contains('solution/client'),
      reason: 'raiz do workspace precisa declarar o membro solution/client',
    );

    final gitignore = File('../../.gitignore').readAsStringSync();
    expect(
      gitignore,
      isNot(contains('/solution/client/')),
      reason: 'o client gerado deixou de ser ignorado (correção de decisão 2026-10-22)',
    );
  });
}
