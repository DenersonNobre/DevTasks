import 'dart:convert';

import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/result.dart';
import 'package:devtasks_app/modules/projects/domain/project_summary.dart';
import 'package:devtasks_app/modules/projects/infrastructure/http_project_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// UUID de teste (contrato `format: uuid`).
const _workspaceId = '00000000-0000-4000-8000-000000000007';
const _projectId = '00000000-0000-4000-8000-000000000001';
const _token = 'tok-abc';

HttpProjectClient _clientReturning(
  int status,
  Map<String, Object?> body, {
  void Function(http.Request request)? onRequest,
}) {
  final mock = MockClient((request) async {
    onRequest?.call(request);
    return http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );
  });
  return HttpProjectClient(client: mock, baseUrl: 'http://api.test');
}

void main() {
  group('UC-08.07 — HttpProjectClient (contrato OpenAPI)', () {
    test('listByWorkspace chama a rota do contrato com Bearer', () async {
      late http.Request captured;
      final client = _clientReturning(
        200,
        {
          'projects': [
            {'id': _projectId, 'workspaceId': _workspaceId, 'name': 'App Mobile'},
          ],
        },
        onRequest: (request) => captured = request,
      );

      final result = await client.listByWorkspace(
        workspaceId: _workspaceId,
        token: _token,
      );

      expect(result, isA<Success>());
      final list = (result as Success).value as List<ProjectSummary>;
      expect(list.single.name, 'App Mobile');
      expect(list.single.id, _projectId);
      expect(captured.method, 'GET');
      expect(captured.url.path, '/workspaces/$_workspaceId/projects');
      expect(captured.headers['authorization'], 'Bearer $_token');
    });

    test('create envia POST com nome e devolve o projeto', () async {
      late http.Request captured;
      final client = _clientReturning(
        201,
        {
          'project': {'id': _projectId, 'workspaceId': _workspaceId, 'name': 'Novo'},
        },
        onRequest: (request) => captured = request,
      );

      final result = await client.create(
        workspaceId: _workspaceId,
        name: 'Novo',
        token: _token,
      );

      expect(result, isA<Success>());
      expect(captured.method, 'POST');
      expect(captured.url.path, '/workspaces/$_workspaceId/projects');
      expect(jsonDecode(captured.body), {'name': 'Novo'});
    });

    test('rename envia PATCH para /projects/{id}', () async {
      late http.Request captured;
      final client = _clientReturning(
        200,
        {
          'project': {'id': _projectId, 'workspaceId': _workspaceId, 'name': 'Renomeado'},
        },
        onRequest: (request) => captured = request,
      );

      final result = await client.rename(
        projectId: _projectId,
        name: 'Renomeado',
        token: _token,
      );

      expect(result, isA<Success>());
      expect(captured.method, 'PATCH');
      expect(captured.url.path, '/projects/$_projectId');
    });

    test('archive chama POST /projects/{id}/archive com Bearer', () async {
      late http.Request captured;
      final client = _clientReturning(
        200,
        {
          'project': {
            'id': _projectId,
            'workspaceId': _workspaceId,
            'name': 'App Mobile',
            'createdAt': '2026-10-24T12:00:00Z',
            'archivedAt': '2026-10-24T22:30:00Z',
          },
        },
        onRequest: (request) => captured = request,
      );

      final result = await client.archive(
        projectId: _projectId,
        token: _token,
      );

      expect(result, isA<Success<ProjectSummary, IFailure>>());
      final summary = (result as Success<ProjectSummary, IFailure>).value;
      expect(summary.isArchived, isTrue);
      expect(captured.method, 'POST');
      expect(captured.url.path, '/projects/$_projectId/archive');
      expect(captured.headers['authorization'], 'Bearer $_token');
    });

    test('409 vira ProjectArchivedFailure em mutações (INV-05)', () async {
      final client = _clientReturning(409, {
        'errorCode': 'ERR_PROJECT_ARCHIVED',
        'message': 'Projeto arquivado não aceita alterações.',
      });

      final result = await client.rename(
        projectId: _projectId,
        name: 'Tentativa',
        token: _token,
      );

      expect(result, isA<Failure>());
      expect((result as Failure).failure, isA<ProjectArchivedFailure>());
    });

    test('403 vira InsufficientRoleFailure (INV-06)', () async {
      final client = _clientReturning(403, {
        'errorCode': 'ERR_INSUFFICIENT_ROLE',
        'message': 'Apenas owner.',
      });

      final result = await client.create(
        workspaceId: _workspaceId,
        name: 'X',
        token: _token,
      );

      expect(result, isA<Failure>());
      expect((result as Failure).failure, isA<InsufficientRoleFailure>());
    });

    test('404 vira NotFoundFailure indistinto (INV-01)', () async {
      final client = _clientReturning(404, {
        'errorCode': 'ERR_NOT_FOUND',
        'message': 'Recurso inexistente ou inacessível.',
      });

      final result = await client.listByWorkspace(
        workspaceId: _workspaceId,
        token: _token,
      );

      expect(result, isA<Failure>());
      expect((result as Failure).failure, isA<NotFoundFailure>());
    });

    test('resposta de sucesso sem project é falha tipada, não crash', () async {
      final client = _clientReturning(201, <String, Object?>{});

      final result = await client.create(
        workspaceId: _workspaceId,
        name: 'X',
        token: _token,
      );

      expect(result, isA<Failure>());
      expect((result as Failure).failure, isA<InfraFailure>());
    });
  });
}
