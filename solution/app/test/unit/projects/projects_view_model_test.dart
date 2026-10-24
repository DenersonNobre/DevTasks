import 'package:devtasks_app/global/kernel/.kernel.dart';
import 'package:devtasks_app/modules/projects/.projects.dart';
import 'package:devtasks_app/modules/projects/presentation/projects_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_project_client.dart';

const _token = 'tok-abc';
final _workspaceId = uuid(7);

void main() {
  late FakeProjectClient client;
  late ProviderContainer container;

  setUp(() {
    client = FakeProjectClient();
    container = ProviderContainer(
      overrides: [projectClientProvider.overrideWithValue(client)],
    );
  });

  tearDown(() => container.dispose());

  ProjectsViewModel viewModel() =>
      container.read(projectsViewModelProvider.notifier);
  ProjectsState readState() => container.read(projectsViewModelProvider);

  group('ProjectsViewModel — listagem (INV-01)', () {
    test('carrega os projetos do workspace e marca ready', () async {
      client.listResult = Success([
        ProjectSummary(id: uuid(1), workspaceId: _workspaceId, name: 'App Mobile'),
        ProjectSummary(id: uuid(2), workspaceId: _workspaceId, name: 'Site'),
      ]);

      await viewModel().load(workspaceId: _workspaceId, token: _token);

      expect(readState().status, ProjectsStatus.ready);
      expect(readState().projects.map((p) => p.name), ['App Mobile', 'Site']);
      expect(client.listCalls, 1);
      expect(client.lastWorkspaceId, _workspaceId);
      expect(client.lastToken, _token);
    });

    test('falha cross-tenant vira estado de erro sem inventar lista', () async {
      client.listResult = const Failure(
        NotFoundFailure('Workspace não encontrado.'),
      );

      await viewModel().load(workspaceId: _workspaceId, token: _token);

      expect(readState().status, ProjectsStatus.error);
      expect(readState().message, 'Workspace não encontrado.');
      expect(readState().projects, isEmpty);
    });
  });

  group('ProjectsViewModel — criação (INV-06)', () {
    test('nome vazio falha no campo e não chama a porta', () async {
      await viewModel().create(
        workspaceId: _workspaceId,
        name: '   ',
        token: _token,
      );

      expect(readState().nameError, 'Informe o nome do projeto.');
      expect(client.createCalls, 0);
    });

    test('owner cria e o projeto entra na lista já carregada', () async {
      await viewModel().load(workspaceId: _workspaceId, token: _token);

      await viewModel().create(
        workspaceId: _workspaceId,
        name: '  App Mobile  ',
        token: _token,
      );

      expect(readState().projects.single.name, 'App Mobile');
      expect(client.lastName, 'App Mobile');
      expect(readState().isSubmitting, isFalse);
    });

    test('developer recebe ERR_INSUFFICIENT_ROLE e a lista não muda', () async {
      client.createResult = const Failure(
        InsufficientRoleFailure('Apenas o owner do workspace pode executar esta ação.'),
      );

      await viewModel().create(
        workspaceId: _workspaceId,
        name: 'App Mobile',
        token: _token,
      );

      expect(readState().projects, isEmpty);
      expect(
        readState().message,
        'Apenas o owner do workspace pode executar esta ação.',
      );
      expect(readState().isSubmitting, isFalse);
    });
  });

  group('ProjectsViewModel — renomeação', () {
    test('renomear substitui o item correspondente na lista', () async {
      client.listResult = Success([
        ProjectSummary(id: uuid(1), workspaceId: _workspaceId, name: 'Antigo'),
      ]);
      await viewModel().load(workspaceId: _workspaceId, token: _token);

      await viewModel().rename(
        projectId: uuid(1),
        name: 'Novo',
        token: _token,
      );

      expect(readState().projects.single.name, 'Novo');
      expect(client.renameCalls, 1);
    });

    test('renomear projeto alheio devolve ERR_NOT_FOUND (INV-01)', () async {
      client.renameResult = const Failure(NotFoundFailure());

      await viewModel().rename(
        projectId: uuid(99),
        name: 'Invasão',
        token: _token,
      );

      expect(readState().message, 'Recurso inexistente ou inacessível.');
    });
  });
}
