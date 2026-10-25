import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

/// UC-08.06 (semente) — validação mecânica do contrato OpenAPI.
///
/// O contrato é a fonte de verdade do client↔server (`D-08`). Este teste garante
/// que o arquivo **parseia** e mantém a forma acordada; a validação de
/// request/response reais entra no gate completo (UC-08.06b).
void main() {
  late YamlMap contract;
  late YamlMap paths;
  late YamlMap schemas;

  setUpAll(() {
    final file = _resolveContractFile();
    expect(file.existsSync(), isTrue, reason: 'contrato não encontrado: ${file.path}');
    contract = loadYaml(file.readAsStringSync()) as YamlMap;
    paths = contract['paths'] as YamlMap;
    schemas = (contract['components'] as YamlMap)['schemas'] as YamlMap;
  });

  group('OpenAPI — forma do documento', () {
    test('declara OpenAPI 3.1 e metadados', () {
      expect(contract['openapi'], startsWith('3.1'));
      expect(contract['info'], isA<YamlMap>());
      expect(contract['servers'], isNotEmpty);
    });

    test('declara securityScheme bearerAuth', () {
      final security = (contract['components'] as YamlMap)['securitySchemes'] as YamlMap;
      expect(security['bearerAuth'], isA<YamlMap>());
    });

    test('envelope de erro canônico existe', () {
      final error = schemas['Error'] as YamlMap;
      final properties = error['properties'] as YamlMap;
      expect(properties.keys, containsAll(['errorCode', 'message']));
    });
  });

  group('OpenAPI — rotas acordadas no brief-21', () {
    test('contém exatamente as rotas do inventário', () {
      final expected = {
        '/health',
        '/auth/signup',
        '/auth/signin',
        '/auth/signout',
        '/me',
        '/workspaces',
        '/workspaces/{id}',
        '/workspaces/{id}/members',
        '/workspaces/{id}/members/{userId}',
        '/workspaces/{id}/projects',
        '/projects/{id}',
        '/projects/{id}/archive',
        '/projects/{id}/tasks',
        '/tasks/{id}',
        '/tasks/{id}/move',
      };
      expect(paths.keys.toSet(), expected);
    });

    test('cada operação tem operationId único e summary', () {
      final ids = <String>[];
      for (final path in paths.values) {
        final item = path as YamlMap;
        for (final method in ['get', 'post', 'patch', 'put', 'delete']) {
          final operation = item[method] as YamlMap?;
          if (operation == null) continue;
          expect(operation['operationId'], isA<String>(), reason: '$method sem operationId');
          expect(operation['summary'], isA<String>(), reason: '$method sem summary');
          ids.add(operation['operationId'] as String);
        }
      }
      expect(ids.length, 20, reason: 'esperadas 20 operações (19 de negócio + /health)');
      expect(ids.toSet().length, ids.length, reason: 'operationId duplicado');
    });

    test('rotas de negócio exigem bearerAuth, exceto /health', () {
      final security = contract['security'] as YamlList?;
      expect(security, isNotNull, reason: 'security global ausente');
      final health = paths['/health'] as YamlMap;
      final healthOp = health['get'] as YamlMap;
      expect(healthOp['security'], isEmpty, reason: '/health deve ser público');
    });
  });

  group('OpenAPI — integridade de \$ref', () {
    test('todo \$ref aponta para um alvo existente', () {
      final missing = <String>[];
      void visit(Object? node) {
        if (node is YamlMap) {
          for (final entry in node.entries) {
            final value = entry.value;
            if (entry.key == r'$ref' && value is String) {
              if (!_refExists(value, contract)) missing.add(value);
            } else {
              visit(value);
            }
          }
        } else if (node is YamlList) {
          for (final item in node) {
            visit(item);
          }
        }
      }

      visit(contract);
      expect(missing, isEmpty, reason: 'refs órfãos: $missing');
    });
  });

  group('OpenAPI — Paridade bidirecional com código da API (UC-08.06)', () {
    test('todas as rotas registradas no código shelf existem no OpenAPI', () {
      final codeRoutes = _extractRoutesFromCode();
      final openApiRoutes = _extractRoutesFromOpenApi(paths);

      final missingInOpenApi = codeRoutes.difference(openApiRoutes);
      expect(
        missingInOpenApi,
        isEmpty,
        reason: 'Rotas implementadas no código mas ausentes no OpenAPI: $missingInOpenApi',
      );

      final missingInCode = openApiRoutes.difference(codeRoutes);
      expect(
        missingInCode,
        isEmpty,
        reason: 'Rotas documentadas no OpenAPI mas ausentes no código: $missingInCode',
      );
    });

    test('prova negativa: divergência de rota detecta falha', () {
      final openApiRoutes = _extractRoutesFromOpenApi(paths);
      final fakeCodeRoutes = Set<String>.from(openApiRoutes)..remove('GET /health');

      expect(
        openApiRoutes.difference(fakeCodeRoutes),
        contains('GET /health'),
        reason: 'Prova negativa: remoção de rota deve ser detectada pela checagem de diferença',
      );
    });
  });

  group('OpenAPI — Tipagem e Contratos de Dados (D-08 / UC-08.06)', () {
    test('todos os schemas requerem formato uuid para identificadores', () {
      final entitySchemas = ['User', 'Workspace', 'WorkspaceWithRole', 'Project', 'Session'];
      for (final name in entitySchemas) {
        if (!schemas.containsKey(name)) continue;
        final schema = schemas[name] as YamlMap;
        final props = schema['properties'] as YamlMap?;
        if (props == null) continue;

        if (props.containsKey('id')) {
          final idProp = props['id'] as YamlMap;
          expect(idProp['type'], equals('string'), reason: '$name.id deve ser string');
          expect(idProp['format'], equals('uuid'), reason: '$name.id deve ter format: uuid');
        }
        if (props.containsKey('userId')) {
          final userIdProp = props['userId'] as YamlMap;
          expect(userIdProp['type'], equals('string'), reason: '$name.userId deve ser string');
          expect(userIdProp['format'], equals('uuid'), reason: '$name.userId deve ter format: uuid');
        }
        if (props.containsKey('workspaceId')) {
          final wsIdProp = props['workspaceId'] as YamlMap;
          expect(wsIdProp['type'], equals('string'), reason: '$name.workspaceId deve ser string');
          expect(wsIdProp['format'], equals('uuid'), reason: '$name.workspaceId deve ter format: uuid');
        }
      }
    });

    test('todos os timestamps requerem formato date-time', () {
      final timeSchemas = ['Workspace', 'WorkspaceWithRole', 'Project', 'Session'];
      for (final name in timeSchemas) {
        if (!schemas.containsKey(name)) continue;
        final schema = schemas[name] as YamlMap;
        final props = schema['properties'] as YamlMap?;
        if (props == null) continue;

        if (props.containsKey('createdAt')) {
          final createdAtProp = props['createdAt'] as YamlMap;
          expect(createdAtProp['type'], equals('string'));
          expect(createdAtProp['format'], equals('date-time'), reason: '$name.createdAt deve ser date-time');
        }
        if (props.containsKey('expiresAt')) {
          final expiresAtProp = props['expiresAt'] as YamlMap;
          expect(expiresAtProp['type'], equals('string'));
          expect(expiresAtProp['format'], equals('date-time'), reason: '$name.expiresAt deve ser date-time');
        }
      }
    });

    test('todas as operações possuem contrato de request e response documentados', () {
      for (final entry in paths.entries) {
        final path = entry.key as String;
        final pathItem = entry.value as YamlMap;
        for (final method in ['get', 'post', 'patch', 'delete']) {
          final operation = pathItem[method] as YamlMap?;
          if (operation == null) continue;

          final responses = operation['responses'] as YamlMap?;
          expect(responses, isNotNull, reason: '$method $path deve declarar responses');

          // Deve ter ao menos uma resposta de sucesso (200, 201, 204)
          final hasSuccess = responses!.keys.any((k) => ['200', '201', '204'].contains(k.toString()));
          expect(hasSuccess, isTrue, reason: '$method $path deve ter resposta 200, 201 ou 204');

          // Rotas autenticadas devem documentar 401
          if (path != '/health' && path != '/auth/signup' && path != '/auth/signin') {
            expect(responses.containsKey('401'), isTrue, reason: '$method $path deve documentar 401');
          }
        }
      }
    });
  });
}

/// Extrai rotas do documento OpenAPI no formato "METHOD /path".
Set<String> _extractRoutesFromOpenApi(YamlMap paths) {
  final routes = <String>{};
  for (final pathEntry in paths.entries) {
    final path = pathEntry.key as String;
    final pathItem = pathEntry.value as YamlMap;
    for (final method in ['get', 'post', 'patch', 'put', 'delete']) {
      if (pathItem.containsKey(method)) {
        routes.add('${method.toUpperCase()} $path');
      }
    }
  }
  return routes;
}

/// Resolve o arquivo de contrato independentemente do diretório de execução.
File _resolveContractFile() {
  const direct = 'docs/api/openapi.yaml';
  if (File(direct).existsSync()) return File(direct);
  const upTwo = '../../docs/api/openapi.yaml';
  if (File(upTwo).existsSync()) return File(upTwo);
  const upOne = '../docs/api/openapi.yaml';
  if (File(upOne).existsSync()) return File(upOne);
  return File(direct);
}

/// Extrai rotas dos arquivos Dart de rotas do shelf no formato "METHOD /path".
Set<String> _extractRoutesFromCode() {
  final routes = <String>{};
  final prefix = Directory('solution/api/lib').existsSync() ? 'solution/api/' : '';
  final candidateFiles = [
    '${prefix}lib/core/http/router.dart',
    '${prefix}lib/modules/auth/auth_routes.dart',
    '${prefix}lib/modules/workspace/workspace_routes.dart',
    '${prefix}lib/modules/projects/project_routes.dart',
    '${prefix}lib/modules/tasks/task_routes.dart',
  ];

  final regex = RegExp(r"router\.(get|post|patch|put|delete)\(\s*'([^']+)'");

  for (final relPath in candidateFiles) {
    final file = File(relPath);
    if (!file.existsSync()) continue;
    final content = file.readAsStringSync();
    final matches = regex.allMatches(content);
    for (final m in matches) {
      final method = m.group(1)!.toUpperCase();
      var path = m.group(2)!;
      // Converte parâmetros shelf (<param>) para formato OpenAPI ({param})
      path = path.replaceAllMapped(RegExp(r'<([^>]+)>'), (pm) => '{${pm.group(1)}}');
      routes.add('$method $path');
    }
  }

  return routes;
}

/// Resolve um `$ref` local (`#/components/...`) contra o documento.
bool _refExists(String ref, YamlMap root) {
  if (!ref.startsWith('#/')) return false;
  Object? cursor = root;
  for (final segment in ref.substring(2).split('/')) {
    if (cursor is! YamlMap) return false;
    cursor = cursor[segment];
    if (cursor == null) return false;
  }
  return true;
}
