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
    final file = File('../../docs/api/openapi.yaml');
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
      expect(ids.length, 14, reason: 'esperadas 14 operações (13 de negócio + /health)');
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
