import 'package:devtasks_api/core/http/api_exception.dart';
import 'package:devtasks_api/core/http/json_payload.dart';
import 'package:test/test.dart';

void main() {
  group('JsonPayload', () {
    test('ensureOnlyAllowedKeys aceita payload com apenas chaves permitidas', () {
      final payload = {'name': 'Dev', 'email': 'dev@test.com'};
      expect(
        () => JsonPayload.ensureOnlyAllowedKeys(payload, {'name', 'email', 'password'}),
        returnsNormally,
      );
    });

    test('ensureOnlyAllowedKeys lança 400 ERR_VALIDATION ao encontrar chave desconhecida (INV-SEC-09 / A-2)', () {
      final payload = {'name': 'Dev', 'email': 'dev@test.com', 'role': 'owner'};
      expect(
        () => JsonPayload.ensureOnlyAllowedKeys(payload, {'name', 'email'}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 400)
              .having((e) => e.errorCode, 'errorCode', 'ERR_VALIDATION')
              .having((e) => e.field, 'field', 'role'),
        ),
      );
    });

    test('requireString extrai string válida e rejeita ausente ou não-string', () {
      final map = {'title': '  Minha Tarefa  ', 'num': 123};
      expect(JsonPayload.requireString(map, 'title'), 'Minha Tarefa');

      expect(
        () => JsonPayload.requireString(map, 'num'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 400)),
      );

      expect(
        () => JsonPayload.requireString(map, 'missing'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 400)),
      );
    });

    test('optionalDouble extrai número ou null e rejeita tipo incompatível', () {
      final map = {'pos': 1500.5, 'nullField': null, 'text': '1500'};
      expect(JsonPayload.optionalDouble(map, 'pos'), 1500.5);
      expect(JsonPayload.optionalDouble(map, 'nullField'), isNull);
      expect(JsonPayload.optionalDouble(map, 'missing'), isNull);

      expect(
        () => JsonPayload.optionalDouble(map, 'text'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 400)),
      );
    });

    test('optionalDate valida YYYY-MM-DD e rejeita timestamp ou texto inválido', () {
      final map = {'valid': '2026-10-25', 'invalid': '2026-10-25T12:00:00Z'};
      expect(JsonPayload.optionalDate(map, 'valid')?.toString(), '2026-10-25');

      expect(
        () => JsonPayload.optionalDate(map, 'invalid'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 400)),
      );
    });
  });
}

