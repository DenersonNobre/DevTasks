import 'package:devtasks_app/global/kernel/.kernel.dart';
import 'package:devtasks_app/modules/projects/.projects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_project_client.dart';

const _token = 'tok-abc';

Widget _harness(FakeProjectClient client) => ProviderScope(
      overrides: [projectClientProvider.overrideWithValue(client)],
      child: MaterialApp(
        home: Scaffold(
          body: ProjectsView(workspaceId: uuid(7), token: _token),
        ),
      ),
    );

void main() {
  late FakeProjectClient client;

  setUp(() => client = FakeProjectClient());

  testWidgets('lista renderiza os projetos carregados', (tester) async {
    client.listResult = Success([
      ProjectSummary(id: uuid(1), workspaceId: uuid(7), name: 'App Mobile'),
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

  testWidgets('renomear projeto abre dialog e atualiza o item na lista', (tester) async {
    final projectId = uuid(1);
    client.listResult = Success([
      ProjectSummary(id: projectId, workspaceId: uuid(7), name: 'Nome Antigo'),
    ]);

    await tester.pumpWidget(_harness(client));
    await tester.pumpAndSettle();

    expect(find.text('Nome Antigo'), findsOneWidget);

    // Toca no botão de editar
    await tester.tap(find.byKey(Key('project-rename-button-$projectId')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('project-rename-dialog')), findsOneWidget);

    // Altera o texto
    await tester.enterText(
      find.byKey(const Key('project-rename-field')),
      'Nome Novo',
    );
    await tester.tap(find.byKey(const Key('project-rename-submit')));
    await tester.pumpAndSettle();

    expect(client.renameCalls, 1);
    expect(client.lastName, 'Nome Novo');
    expect(find.text('Nome Novo'), findsOneWidget);
    expect(find.byKey(const Key('project-rename-dialog')), findsNothing);
  });
}
