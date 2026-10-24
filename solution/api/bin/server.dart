import 'dart:io';

import 'package:devtasks_api/devtasks_api.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Entrypoint da API (UC-08.01).
///
/// Sobe o servidor shelf com o handler de [buildHandler] na porta configurada.
Future<void> main() async {
  final config = AppConfig.current();
  final server = await shelf_io.serve(
    buildHandler(corsOrigin: config.corsOrigin),
    config.host,
    config.port,
  );

  stdout.writeln(
    'DevTasks API ouvindo em http://${server.address.address}:${server.port} '
    '(db: ${config.databaseUrl.replaceAll(RegExp(r'://[^@]*@'), '://<redacted>@')})',
  );
}
