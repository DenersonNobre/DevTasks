import 'package:devtasks_app/global/kernel/.kernel.dart';
import 'package:devtasks_app/modules/projects/.projects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_project_client.dart';

const _token = 'tok-abc';
const _workspaceId = 7;

Widget _harness(FakeProjectClient client) => ProviderScope(
      overrides: [projectClientProvider.overrideWithValue(client)],
      child: const MaterialApp(
        home: Scaffold(
          body: ProjectsView(workspaceId: _workspaceId, token: _token),
        ),
      ),
    );

void main() {
  late FakeProjectClient client;

  setUp(() => client = FakeProjectClient());

  testWidgets('lista renderiza os projetos carregados', (tester) async {
    client.listResult = const Success([
      ProjectSummary(id: 1, workspaceId: _workspaceId, name: 'App Mobile'),
    ]);

    await tester.pumpWidget(_harness(client));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('projects-list')), findsOneWidget);
    expect(find.text('App Mobile'), findsOneWidget);
    expect(find.byKey(const Key('projects-empty-state')), findsNothing);
  });

  testWidgets('estado vazio é explícito', (tester) async {
    client.listResult = const Success([]);

    await tester.pumpWidget(_harness(client));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('projects-empty-state')), findsOneWidget);
  });

  testWidgets('erro exibe mensagem e botão de retry', (tester) async {
    client.listResult = const Failure(NotFoundFailure('Workspace não encontrado.'));

    await tester.pumpWidget(_harness(client));
    await tester.pumpAndSettle();

    expect(find.text('Workspace não encontrado.'), findsOneWidget);
    expect(find.byKey(const Key('projects-retry-button')), findsOneWidget);
  });

  testWidgets('criar projeto limpa o campo e adiciona o item', (tester) async {
    client.listResult = const Success([]);

    await tester.pumpWidget(_harness(client));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('project-name-field')),
      'App Mobile',
    );
    await tester.tap(find.byKey(const Key('project-create-button')));
    await tester.pumpAndSettle();

    expect(client.createCalls, 1);
    expect(client.lastName, 'App Mobile');
    expect(find.text('App Mobile'), findsOneWidget);
  });

  testWidgets('nome vazio mostra erro de campo sem chamar a porta', (tester) async {
    client.listResult = const Success([]);

    await tester.pumpWidget(_harness(client));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('project-create-button')));
    await tester.pumpAndSettle();

    expect(find.text('Informe o nome do projeto.'), findsOneWidget);
    expect(client.createCalls, 0);
  });
}
