// solution/app/test/widget/navigation_flow_test.dart
// Teste de jornada navegacional ponta a ponta (R1 da auditoria de 2026-10-25).
// Login -> Seleção de Workspace -> Projetos -> Tarefas/Kanban -> Comentários.

import 'package:devtasks_app/global/kernel/result.dart';
import 'package:devtasks_app/global/session/.session.dart';
import 'package:devtasks_app/main.dart';
import 'package:devtasks_app/modules/auth/domain/auth_client.dart';
import 'package:devtasks_app/modules/auth/infrastructure/auth_client_provider.dart';
import 'package:devtasks_app/modules/comments/domain/comment_item.dart';
import 'package:devtasks_app/modules/comments/infrastructure/comment_client_provider.dart';
import 'package:devtasks_app/modules/projects/domain/project_summary.dart';
import 'package:devtasks_app/modules/projects/infrastructure/project_client_provider.dart';
import 'package:devtasks_app/modules/tasks/domain/task_item.dart';
import 'package:devtasks_app/modules/tasks/infrastructure/task_client_provider.dart';
import 'package:devtasks_app/modules/workspace/domain/workspace_item.dart';
import 'package:devtasks_app/modules/workspace/infrastructure/workspace_client_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_auth_client.dart';
import '../support/fake_comment_client.dart';
import '../support/fake_project_client.dart';
import '../support/fake_task_client.dart';
import '../support/fake_workspace_client.dart';
import '../support/in_memory_session_store.dart';

void main() {
  late FakeAuthClient fakeAuth;
  late FakeWorkspaceClient fakeWorkspace;
  late FakeProjectClient fakeProject;
  late FakeTaskClient fakeTask;
  late FakeCommentClient fakeComment;
  late InMemorySessionStore sessionStore;

  setUp(() {
    fakeAuth = FakeAuthClient();
    fakeWorkspace = FakeWorkspaceClient();
    fakeProject = FakeProjectClient();
    fakeTask = FakeTaskClient();
    fakeComment = FakeCommentClient();
    sessionStore = InMemorySessionStore();

    // Dados sementes para a jornada
    fakeAuth.signInResult = const Success(
      AuthSession(
        userId: 'user-journey-1',
        token: 'tok-journey-xyz',
      ),
    );

    fakeWorkspace.workspaces.add(
      WorkspaceItem(
        id: 'ws-journey-1',
        name: 'Workspace Principal',
        role: 'owner',
        createdAt: DateTime.utc(2026, 10, 25),
      ),
    );

    fakeProject.listResult = const Success([
      ProjectSummary(
        id: 'proj-journey-1',
        workspaceId: 'ws-journey-1',
        name: 'App DevTasks',
      ),
    ]);

    fakeTask.listResult = const Success([
      TaskItem(
        id: 'task-journey-1',
        projectId: 'proj-journey-1',
        title: 'Implementar navegação ponta a ponta',
      ),
    ]);

    fakeComment.comments.add(
      CommentItem(
        id: 'comment-journey-1',
        taskId: 'task-journey-1',
        userId: 'user-journey-1',
        authorName: 'Denerson',
        content: 'Primeiro comentário da jornada',
        createdAt: DateTime.utc(2026, 10, 25, 14, 0),
      ),
    );
  });

  Widget createHarness() {
    return ProviderScope(
      overrides: [
        sessionStoreProvider.overrideWithValue(sessionStore),
        authClientProvider.overrideWithValue(fakeAuth),
        workspaceClientProvider.overrideWithValue(fakeWorkspace),
        projectClientProvider.overrideWithValue(fakeProject),
        taskClientProvider.overrideWithValue(fakeTask),
        commentClientProvider.overrideWithValue(fakeComment),
      ],
      child: const DevTasksApp(),
    );
  }

  testWidgets('jornada completa: login -> workspace -> projetos -> tarefas -> timeline de comentários', (tester) async {
    // 1. Inicializa o app e espera carregar o login
    await tester.pumpWidget(createHarness());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-email')), findsOneWidget);
    expect(find.byKey(const Key('login-password')), findsOneWidget);

    // 2. Preenche e submete credenciais
    await tester.enterText(
      find.byKey(const Key('login-email')),
      'usuario@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'SenhaSegura123!',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    // 3. Verifica transição para a área privada e renderização de workspace/projetos
    expect(find.text('Workspace Principal'), findsOneWidget);
    expect(find.byKey(const Key('projects-list')), findsOneWidget);
    expect(find.text('App DevTasks'), findsOneWidget);

    // 4. Clica no projeto "App DevTasks" para navegar para suas tarefas
    await tester.tap(find.text('App DevTasks'));
    await tester.pumpAndSettle();

    // 5. Verifica que está na tela de tarefas do projeto
    expect(find.text('Implementar navegação ponta a ponta'), findsOneWidget);
    expect(find.byKey(const Key('task-comments-button-task-journey-1')), findsOneWidget);

    // 6. Clica no botão de comentários da tarefa
    await tester.tap(find.byKey(const Key('task-comments-button-task-journey-1')));
    await tester.pumpAndSettle();

    // 7. Verifica abertura da timeline de comentários com o comentário semente
    expect(find.text('Primeiro comentário da jornada'), findsOneWidget);
    expect(find.text('Denerson'), findsOneWidget);
    expect(find.byKey(const Key('comment-input-field')), findsOneWidget);

    // 8. Digita novo comentário e envia
    await tester.enterText(
      find.byKey(const Key('comment-input-field')),
      'Comentário adicionado via teste de jornada!',
    );
    await tester.tap(find.byKey(const Key('comment-submit-button')));
    await tester.pumpAndSettle();

    // 9. Confirma que o novo comentário está na timeline
    expect(find.text('Comentário adicionado via teste de jornada!'), findsOneWidget);
  });
}
