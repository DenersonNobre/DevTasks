import 'dart:io';

/// Uma migration versionada carregada do disco.
class Migration {
  const Migration({
    required this.version,
    required this.name,
    required this.sql,
  });

  /// Prefixo numérico do arquivo (`0001` em `0001_initial.sql`).
  final String version;

  /// Nome legível (restante do arquivo, sem `.sql`).
  final String name;

  /// Conteúdo SQL, executado em um único comando.
  final String sql;

  @override
  String toString() => '$version — $name';
}

/// Erro de contrato das migrations (arquivo malformado ou versão duplicada).
class MigrationFormatException implements Exception {
  const MigrationFormatException(this.message);

  final String message;

  @override
  String toString() => 'MigrationFormatException: $message';
}

/// Carrega e ordena as migrations de um diretório.
///
/// Regra de nome: `<versao>_<nome>.sql`, onde `versao` é numérica.
/// Ordenação é lexicográfica sobre versão com largura fixa — determinística.
List<Migration> loadMigrations(Directory directory) {
  if (!directory.existsSync()) {
    return const [];
  }

  final files = directory
      .listSync()
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.sql'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final migrations = <Migration>[];
  final seen = <String>{};

  for (final file in files) {
    final migration = _parse(file);
    if (!seen.add(migration.version)) {
      throw MigrationFormatException(
        'Versão duplicada: ${migration.version} (${file.path})',
      );
    }
    migrations.add(migration);
  }

  return migrations;
}

Migration _parse(File file) {
  final fileName = file.uri.pathSegments.last;
  final base = fileName.substring(0, fileName.length - '.sql'.length);
  final separator = base.indexOf('_');

  if (separator <= 0) {
    throw MigrationFormatException(
      'Nome inválido "$fileName". Esperado <versao>_<nome>.sql',
    );
  }

  final version = base.substring(0, separator);
  final isNumeric = RegExp(r'^\d+$').hasMatch(version);
  if (!isNumeric) {
    throw MigrationFormatException(
      'Versão não numérica "$version" em "$fileName".',
    );
  }

  return Migration(
    version: version,
    name: base.substring(separator + 1),
    sql: file.readAsStringSync(),
  );
}
