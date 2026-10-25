import 'dart:io';

import 'package:devtasks_api/devtasks_api.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

/// Integração real dos repositórios PostgreSQL (B-2 do laudo de auditoria).
///
/// Sem `DEVTASKS_TEST_DATABASE_URL` o teste é declaradamente pulado. O gate
/// `tools/test.ps1 -Db` transforma a ausência da variável em **falha**, para que
/// "persistência validada" nunca seja afirmação de fachada.
///
/// Cada caso cobre um risco que o fake de `test/unit` não alcança: mapeamento de
/// `23505`, violação de `CHECK`, leitura de `timestamptz`, CTE de criação
/// atômica e cast `::uuid` sobre identificador inválido.
void main() {
  final dsn = Platform.environment['DEVTASKS_TEST_DATABASE_URL'];
  final skipReason = dsn == null || dsn.isEmpty
      ? 'DEVTASKS_TEST_DATABASE_URL não definido (sem Postgres)'
      : null;

  group('Repositórios PostgreSQL (B-2 / D-08)', () {
    late Pool<Session> pool;
    late ISqlExecutor sql;

    setUpAll(() async {
      pool = openPool(dsn!);
      sql = PgSqlExecutor(pool);
      await sql.execute('DROP SCHEMA public CASCADE');
      await sql.execute('CREATE SCHEMA public');
      await Migrator(
        sql: sql,
        store: SqlMigrationStore(sql),
        migrations: loadMigrations(Directory('migrations')),
      ).up();
    });

    setUp(() async {
      await sql.execute(
        'TRUNCATE devtasks_task, devtasks_session, devtasks_workspace_member, devtasks_project, '
        'devtasks_workspace, devtasks_user CASCADE',
      );
    });

    tearDownAll(() async {
      await pool.close();
    });

    Future<String> createUser({String email = 'ana@example.com'}) async {
      final created = await PostgresUserRepository(sql).create(
        name: 'Ana',
        email: email,
        passwordHash: r'$argon2id$fake',
      );
      return (created as UserCreated).user.id;
    }

    group('PostgresUserRepository', () {
      test('create persiste e devolve id; e-mail normalizado é o da consulta', () async {
        final repo = PostgresUserRepository(sql);

        final created = await repo.create(
          name: 'Ana',
          email: 'ana@example.com',
          passwordHash: r'$argon2id$fake',
        ) as UserCreated;

        expect(created.user.name, 'Ana');
        expect(created.user.emailVerified, isFalse);
        expect(await repo.existsByEmail('ana@example.com'), isTrue);
        expect(await repo.existsByEmail('outra@example.com'), isFalse);
      });

      test('create mapeia violação de UNIQUE (23505) em EmailTaken (INV-08)', () async {
        final repo = PostgresUserRepository(sql);
        await createUser();

        final second = await repo.create(
          name: 'Bia',
          email: 'ana@example.com',
          passwordHash: r'$argon2id$fake',
        );

        expect(second, isA<EmailTaken>());
      });

      test('findById devolve UserProfile e null para id inexistente', () async {
        final repo = PostgresUserRepository(sql);
        final id = await createUser();

        final profile = await repo.findById(id);
        expect(profile?.userId, id);
        expect(profile?.email, 'ana@example.com');
        expect(
          await repo.findById('00000000-0000-4000-8000-000000000000'),
          isNull,
        );
      });

      test('findByEmail expõe o hash (porta segregada) e findEmailById resolve', () async {
        final repo = PostgresUserRepository(sql);
        final id = await createUser();

        final credential = await repo.findByEmail('ana@example.com');
        expect(credential?.id, id);
        expect(credential?.passwordHash, r'$argon2id$fake');
        expect(await repo.findEmailById(id), 'ana@example.com');
      });
    });

    group('PostgresSessionRepository', () {
      test('save persiste apenas o digest e preserva timestamptz (INV-SEC-17)', () async {
        final userId = await createUser();
        final repo = PostgresSessionRepository(sql);
        final createdAt = DateTime.utc(2026, 10, 24, 12);
        final expiresAt = createdAt.add(const Duration(hours: 8));

        await repo.save(SessionRecord(
          userId: userId,
          tokenHash: 'a' * 64,
          createdAt: createdAt,
          expiresAt: expiresAt,
        ));

        final found = await repo.findByTokenHash('a' * 64);
        expect(found?.userId, userId);
        expect(found?.createdAt.toUtc(), createdAt);
        expect(found?.expiresAt.toUtc(), expiresAt);
        expect(found?.revokedAt, isNull);
      });

      test('revokeByTokenHash marca revoked_at e é idempotente', () async {
        final userId = await createUser();
        final repo = PostgresSessionRepository(sql);
        await repo.save(SessionRecord(
          userId: userId,
          tokenHash: 'b' * 64,
          createdAt: DateTime.utc(2026, 10, 24),
          expiresAt: DateTime.utc(2026, 10, 25),
        ));

        await repo.revokeByTokenHash('b' * 64, DateTime.utc(2026, 10, 24, 13));
        final first = await repo.findByTokenHash('b' * 64);
        expect(first?.isRevoked, isTrue);

        // Segunda revogação não altera a marca original (WHERE revoked_at IS NULL).
        await repo.revokeByTokenHash('b' * 64, DateTime.utc(2026, 10, 24, 20));
        final second = await repo.findByTokenHash('b' * 64);
        expect(second?.revokedAt?.toUtc(), DateTime.utc(2026, 10, 24, 13));
      });
    });

    group('PostgresWorkspaceRepository', () {
      test('createWithRole cria workspace + owner na mesma instrução (INV-09)', () async {
        final ownerId = await createUser();
        final repo = PostgresWorkspaceRepository(sql);

        final created = await repo.createWithRole(
          name: 'Squad Atlas',
          ownerUserId: ownerId,
        );

        expect(created.role, WorkspaceMemberRole.owner);
        expect(await repo.getMemberRole(
          workspaceId: created.workspace.id,
          userId: ownerId,
        ), WorkspaceMemberRole.owner);
        expect((await repo.listByUserId(ownerId)).single.workspace.name,
            'Squad Atlas');
      });

      test('getMemberRole devolve null para quem não é membro (INV-01)', () async {
        final ownerId = await createUser(email: 'owner@example.com');
        final outsiderId = await createUser(email: 'outsider@example.com');
        final repo = PostgresWorkspaceRepository(sql);
        final created = await repo.createWithRole(name: 'W', ownerUserId: ownerId);

        expect(await repo.getMemberRole(
          workspaceId: created.workspace.id,
          userId: outsiderId,
        ), isNull);
      });

      test('addMember mapeia duplicata em MemberAlreadyExists (INV-09 / 23505)', () async {
        final ownerId = await createUser(email: 'owner@example.com');
        final memberId = await createUser(email: 'member@example.com');
        final repo = PostgresWorkspaceRepository(sql);
        final created = await repo.createWithRole(name: 'W', ownerUserId: ownerId);

        final first = await repo.addMember(
          workspaceId: created.workspace.id,
          userId: memberId,
          role: WorkspaceMemberRole.developer,
        );
        expect(first, isA<MemberAdded>());

        final second = await repo.addMember(
          workspaceId: created.workspace.id,
          userId: memberId,
          role: WorkspaceMemberRole.viewer,
        );
        expect(second, isA<MemberAlreadyExists>());
        // A readição não altera o papel vigente.
        expect(await repo.getMemberRole(
          workspaceId: created.workspace.id,
          userId: memberId,
        ), WorkspaceMemberRole.developer);
      });

      test('addMember devolve MemberUserNotFound para usuário inexistente', () async {
        final ownerId = await createUser();
        final repo = PostgresWorkspaceRepository(sql);
        final created = await repo.createWithRole(name: 'W', ownerUserId: ownerId);

        final outcome = await repo.addMember(
          workspaceId: created.workspace.id,
          userId: '00000000-0000-4000-8000-000000000000',
          role: WorkspaceMemberRole.developer,
        );
        expect(outcome, isA<MemberUserNotFound>());
      });

      test('removeMember recusa remover o último owner (SPEC §4.1)', () async {
        final ownerId = await createUser();
        final repo = PostgresWorkspaceRepository(sql);
        final created = await repo.createWithRole(name: 'W', ownerUserId: ownerId);

        final outcome = await repo.removeMember(
          workspaceId: created.workspace.id,
          userId: ownerId,
        );

        expect(outcome, isA<CannotRemoveLastOwner>());
        expect(await repo.getMemberRole(
          workspaceId: created.workspace.id,
          userId: ownerId,
        ), WorkspaceMemberRole.owner);
      });

      test('removeMember remove membro comum e devolve MemberNotFound na repetição', () async {
        final ownerId = await createUser(email: 'owner@example.com');
        final memberId = await createUser(email: 'member@example.com');
        final repo = PostgresWorkspaceRepository(sql);
        final created = await repo.createWithRole(name: 'W', ownerUserId: ownerId);
        await repo.addMember(
          workspaceId: created.workspace.id,
          userId: memberId,
          role: WorkspaceMemberRole.viewer,
        );

        expect(
          await repo.removeMember(
            workspaceId: created.workspace.id,
            userId: memberId,
          ),
          isA<MemberRemoved>(),
        );
        expect(
          await repo.removeMember(
            workspaceId: created.workspace.id,
            userId: memberId,
          ),
          isA<MemberNotFound>(),
        );
      });

      test('updateName persiste o nome e devolve o papel do solicitante', () async {
        final ownerId = await createUser();
        final repo = PostgresWorkspaceRepository(sql);
        final created = await repo.createWithRole(name: 'Antigo', ownerUserId: ownerId);

        final updated = await repo.updateName(
          workspaceId: created.workspace.id,
          name: 'Novo',
          userId: ownerId,
        );

        expect(updated?.workspace.name, 'Novo');
        expect(updated?.role, WorkspaceMemberRole.owner);
      });
    });

    group('PostgresProjectRepository', () {
      test('create/list/find/updateName contra o workspace dono', () async {
        final ownerId = await createUser();
        final workspaces = PostgresWorkspaceRepository(sql);
        final ws = await workspaces.createWithRole(name: 'W', ownerUserId: ownerId);
        final repo = PostgresProjectRepository(sql);

        final created = await repo.create(
          workspaceId: ws.workspace.id,
          name: 'Onboarding',
        );
        expect(created.workspaceId, ws.workspace.id);
        expect((await repo.listByWorkspace(ws.workspace.id)).single.name,
            'Onboarding');

        final updated = await repo.updateName(
          projectId: created.id,
          name: 'Onboarding 2026',
        );
        expect(updated?.name, 'Onboarding 2026');
        expect((await repo.findById(created.id))?.name, 'Onboarding 2026');
      });

      test('project de workspace inexistente viola a FK (INV-02)', () async {
        final repo = PostgresProjectRepository(sql);

        expect(
          () => repo.create(
            workspaceId: '00000000-0000-4000-8000-000000000000',
            name: 'Órfão',
          ),
          throwsA(isA<PgException>()),
        );
      });
    });

    group('PostgresTaskRepository', () {
      test('create, listByProject, findById, update e delete persistem no Postgres (D-08 / INV-04)', () async {
        final userRepo = PostgresUserRepository(sql);
        final wsRepo = PostgresWorkspaceRepository(sql);
        final projRepo = PostgresProjectRepository(sql);
        final taskRepo = PostgresTaskRepository(sql);

        final uRes = await userRepo.create(
          name: 'Task Tester',
          email: 'tasker@example.com',
          passwordHash: 'hash',
        );
        final userId = (uRes as UserCreated).user.id;
        final ws = await wsRepo.createWithRole(
          name: 'Task WS',
          ownerUserId: userId,
        );
        final proj = await projRepo.create(
          workspaceId: ws.workspace.id,
          name: 'Sprint 1',
        );

        // 1. Create - nasce no backlog com posição incremental
        final task1 = await taskRepo.create(
          projectId: proj.id,
          title: 'Primeira Tarefa',
          priority: TaskPriority.high,
          description: 'Desc 1',
        );
        expect(task1.id, isNotEmpty);
        expect(task1.title, 'Primeira Tarefa');
        expect(task1.status, TaskStatus.backlog);
        expect(task1.priority, TaskPriority.high);
        expect(task1.position, 1000.0);

        final task2 = await taskRepo.create(
          projectId: proj.id,
          title: 'Segunda Tarefa',
        );
        expect(task2.position, 2000.0);

        // 2. List
        final tasks = await taskRepo.listByProject(proj.id);
        expect(tasks.length, 2);
        expect(tasks.first.title, 'Primeira Tarefa');
        expect(tasks.last.title, 'Segunda Tarefa');

        // 3. FindById
        final found = await taskRepo.findById(task1.id);
        expect(found?.title, 'Primeira Tarefa');
        expect(found?.description, 'Desc 1');

        // 4. Update
        final updated = await taskRepo.update(
          taskId: task1.id,
          title: 'Tarefa Atualizada',
          priority: TaskPriority.low,
        );
        expect(updated?.title, 'Tarefa Atualizada');
        expect(updated?.priority, TaskPriority.low);

        // 5. Delete
        final deleted = await taskRepo.delete(task1.id);
        expect(deleted, isTrue);
        expect(await taskRepo.findById(task1.id), isNull);
        final remaining = await taskRepo.listByProject(proj.id);
        expect(remaining.length, 1);
        expect(remaining.first.id, task2.id);
      });
    });

    group('Caracterização de fronteira (achado A-1 do laudo)', () {
      test('id não-UUID falha no cast do banco, não na fronteira', () async {
        final repo = PostgresWorkspaceRepository(sql);

        // Documenta o comportamento atual: o path param cru chega ao `::uuid` e
        // produz PgException (22P02), que a borda traduz em 500. Quando a
        // validação de UUID entrar na fronteira, este teste deve mudar.
        expect(
          () => repo.findById('nao-e-uuid'),
          throwsA(isA<PgException>()),
        );
      });
    });
  }, skip: skipReason);
}
