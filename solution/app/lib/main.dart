import 'package:devtasks_app/devtasks_app.dart';
import 'package:devtasks_app/global/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DevTasksApp());
}

/// Minimal app shell — placeholder until the real UI lands (EPIC-01+).
class DevTasksApp extends StatelessWidget {
  const DevTasksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const Scaffold(body: Center(child: Text(appName))),
    );
  }
}
