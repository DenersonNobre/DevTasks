// solution/app/test/unit/comments/http_comment_client_test.dart
// Teste unitário do adaptador HTTP do módulo de comentários (OpenAPI 3.1 / UC-05.01).

import 'dart:convert';

import 'package:devtasks_app/global/kernel/failures.dart';
import 'package:devtasks_app/global/kernel/result.dart';
import 'package:devtasks_app/modules/comments/domain/comment_item.dart';
import 'package:devtasks_app/modules/comments/infrastructure/http_comment_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _taskId = '00000000-0000-4000-8000-000000000001';
const _token = 'token-comments-test';

HttpCommentClient _clientReturning(
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
  return HttpCommentClient(client: mock, baseUrl: 'http://api.test');
}

void main() {
  group('HttpCommentClient (EPIC-05 / UC-05.01 / RF-12)', () {
    test('listByTask chama GET /tasks/{id}/comments com Bearer e mapeia lista', () async {
      late http.Request captured;
      final client = _clientReturning(
        200,
        {
          'comments': [
            {
              'id': 'comment-1',
              'taskId': _taskId,
              'userId': 'user-1',
              'authorName': 'Alice',
              'content': 'Primeiro comentário',
              'createdAt': '2026-10-25T12:00:00.000Z',
            },
            {
              'id': 'comment-2',
              'taskId': _taskId,
              'userId': 'user-2',
              'authorName': 'Bob',
              'content': 'Segundo comentário',
              'createdAt': '2026-10-25T13:00:00.000Z',
            },
          ],
        },
        onRequest: (r) => captured = r,
      );

      final result = await client.listByTask(taskId: _taskId, token: _token);

      expect(captured.method, 'GET');
      expect(captured.url.path, '/tasks/$_taskId/comments');
      expect(captured.headers['authorization'], 'Bearer $_token');

      expect(result, isA<Success<List<CommentItem>, IFailure>>());
      final list = (result as Success<List<CommentItem>, IFailure>).value;
      expect(list.length, 2);
      expect(list[0].id, 'comment-1');
      expect(list[0].authorName, 'Alice');
      expect(list[0].content, 'Primeiro comentário');
      expect(list[1].id, 'comment-2');
      expect(list[1].authorName, 'Bob');
    });

    test('create chama POST /tasks/{id}/comments com body JSON e mapeia comentário criado', () async {
      late http.Request captured;
      final client = _clientReturning(
        201,
        {
          'comment': {
            'id': 'new-comment-id',
            'taskId': _taskId,
            'userId': 'user-current',
            'authorName': 'Eu Mesmo',
            'content': 'Novo comentário de teste',
            'createdAt': '2026-10-25T14:00:00.000Z',
          },
        },
        onRequest: (r) => captured = r,
      );

      final result = await client.create(
        taskId: _taskId,
        content: 'Novo comentário de teste',
        token: _token,
      );

      expect(captured.method, 'POST');
      expect(captured.url.path, '/tasks/$_taskId/comments');
      expect(captured.headers['authorization'], 'Bearer $_token');
      final sentBody = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(sentBody['content'], 'Novo comentário de teste');

      expect(result, isA<Success<CommentItem, IFailure>>());
      final created = (result as Success<CommentItem, IFailure>).value;
      expect(created.id, 'new-comment-id');
      expect(created.content, 'Novo comentário de teste');
      expect(created.authorName, 'Eu Mesmo');
    });

    test('listByTask mapeia 404 em NotFoundFailure', () async {
      final client = _clientReturning(404, {'errorCode': 'ERR_NOT_FOUND', 'message': 'Tarefa não encontrada'});
      final result = await client.listByTask(taskId: _taskId, token: _token);

      expect(result, isA<Failure<List<CommentItem>, IFailure>>());
      final failure = (result as Failure<List<CommentItem>, IFailure>).failure;
      expect(failure, isA<NotFoundFailure>());
    });

    test('create mapeia 400 em ValidationFailure', () async {
      final client = _clientReturning(400, {'errorCode': 'ERR_VALIDATION', 'message': 'Conteúdo vazio'});
      final result = await client.create(taskId: _taskId, content: '', token: _token);

      expect(result, isA<Failure<CommentItem, IFailure>>());
      final failure = (result as Failure<CommentItem, IFailure>).failure;
      expect(failure, isA<ValidationFailure>());
    });
  });
}
