import 'package:devtasks_app/devtasks_app.dart';
import 'package:devtasks_app/global/router/app_routes.dart';
import 'package:devtasks_app/global/router/route_guard.dart';
import 'package:devtasks_app/global/session/.session.dart';
import 'package:devtasks_app/global/shell/private_area_view.dart';
import 'package:devtasks_app/global/theme/app_theme.dart';
import 'package:devtasks_app/modules/auth/.auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Container de inicialização e restauração segura da sessão (boot)
  final container = ProviderContainer();
  await container.read(sessionControllerProvider).restore();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DevTasksApp(),
    ),
  );
}

/// App shell com navegação protegida por [RouteGuard] (F1.8).
class DevTasksApp extends ConsumerWidget {
  const DevTasksApp({
    super.key,
    this.initialRoute,
    this.routeGuard = const RouteGuard(),
  });

  final String? initialRoute;
  final RouteGuard routeGuard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sessionControllerProvider);

    return MaterialApp(
      title: appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      initialRoute: initialRoute ?? AppRoutes.login,
      onGenerateRoute: (settings) => _generateRoute(
        settings,
        ref.read(sessionControllerProvider).state,
      ),
    );
  }

  Route<dynamic>? _generateRoute(
    RouteSettings settings,
    SessionState session,
  ) {
    final targetName = settings.name ?? AppRoutes.login;
    final requiresSession = targetName == AppRoutes.privateArea;

    // 1. Rota privada sem sessão redireciona para login
    final decision = routeGuard.decide(
      requiresSession: requiresSession,
      session: session,
    );

    if (decision == RouteDecision.redirectToLogin) {
      return MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.login),
        builder: (_) => const LoginView(),
      );
    }

    // 2. Rota de autenticação pública com sessão ativa redireciona para a área privada
    final isAuthRoute =
        targetName == AppRoutes.login || targetName == AppRoutes.register;
    if (isAuthRoute && session.isAuthenticated) {
      return MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.privateArea),
        builder: (_) => const PrivateAreaView(),
      );
    }

    // 3. Resolução normal de rota
    return switch (targetName) {
      AppRoutes.register => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const RegisterView(),
        ),
      AppRoutes.privateArea => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const PrivateAreaView(),
        ),
      _ => MaterialPageRoute<void>(
          settings: const RouteSettings(name: AppRoutes.login),
          builder: (_) => const LoginView(),
        ),
    };
  }
}
