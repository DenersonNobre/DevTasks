import 'dart:io';

import 'package:devtasks_api/devtasks_api.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Entrypoint da API (UC-08.01 / UC-08.03).
///
/// Sobe o servidor shelf com o handler de [buildHandler] na porta configurada.
Future<void> main() async {
  final config = AppConfig.current();
  final pool = openPool(config.databaseUrl);
  final sql = PgSqlExecutor(pool);

  final userRepo = PostgresUserRepository(sql);
  final sessionRepo = PostgresSessionRepository(sql);
  final hasher = Argon2PasswordHasher();
  final signUpHandler = SignUpHandler(userRepo, hasher);
  final signInHandler = SignInHandler(userRepo, hasher);
  final sessionService = SessionService(
    repository: sessionRepo,
    credentialRepository: userRepo,
    defaultTtl: Duration(hours: config.sessionTtlHours),
  );
  final rateLimiter = InMemoryRateLimiter(now: DateTime.now);

  final authRoutes = AuthRoutes(
    signUpHandler: signUpHandler,
    signInHandler: signInHandler,
    sessionService: sessionService,
    userRepository: userRepo,
    rateLimiter: rateLimiter,
  );

  final workspaceRepo = PostgresWorkspaceRepository(sql);
  final workspaceRoutes = WorkspaceRoutes(
    workspaceRepository: workspaceRepo,
    authenticator: sessionService,
  );

  final projectRepo = PostgresProjectRepository(sql);
  final projectRoutes = ProjectRoutes(
    projectRepository: projectRepo,
    workspaceRepository: workspaceRepo,
    authenticator: sessionService,
  );

  final taskRepo = PostgresTaskRepository(sql);
  final taskRoutes = TaskRoutes(
    taskRepository: taskRepo,
    projectRepository: projectRepo,
    workspaceRepository: workspaceRepo,
    authenticator: sessionService,
  );

  final commentRepo = PostgresCommentRepository(sql);
  final commentRoutes = CommentRoutes(
    commentRepository: commentRepo,
    taskRepository: taskRepo,
    projectRepository: projectRepo,
    workspaceRepository: workspaceRepo,
    authenticator: sessionService,
  );

  final handler = buildHandler(
    corsOrigin: config.corsOrigin,
    authRoutes: authRoutes,
    workspaceRoutes: workspaceRoutes,
    projectRoutes: projectRoutes,
    taskRoutes: taskRoutes,
    commentRoutes: commentRoutes,
  );

  final server = await shelf_io.serve(
    handler,
    config.host,
    config.port,
  );

  stdout.writeln(
    'DevTasks API ouvindo em http://${server.address.address}:${server.port} '
    '(db: ${config.databaseUrl.replaceAll(RegExp(r'://[^@]*@'), '://<redacted>@')})',
  );
}
