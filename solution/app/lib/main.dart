import 'package:devtasks_app/devtasks_app.dart';
import 'package:devtasks_app/global/router/app_routes.dart';
import 'package:devtasks_app/global/shell/private_area_view.dart';
import 'package:devtasks_app/global/theme/app_theme.dart';
import 'package:devtasks_app/modules/auth/.auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() => runApp(const ProviderScope(child: DevTasksApp()));

/// App shell: rotas de autenticação (F1.6) e placeholder da área privada.
///
/// Os adaptadores reais (`AuthClient`, `SessionStore`) entram na borda quando a
/// emissão de token existir no servidor — follow-up declarado, não silencioso.
class DevTasksApp extends StatelessWidget {
  const DevTasksApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: appName,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.login,
        routes: {
          AppRoutes.login: (_) => const LoginView(),
          AppRoutes.register: (_) => const RegisterView(),
          AppRoutes.privateArea: (_) => const PrivateAreaView(),
        },
      );
}
