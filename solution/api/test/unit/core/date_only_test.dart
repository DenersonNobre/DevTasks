// solution/api/test/unit/core/date_only_test.dart
// Testes do Value Object DateOnly (formato estrito YYYY-MM-DD / OpenAPI 3.1 format: date - R5).

import 'package:devtasks_api/core/types/date_only.dart';
import 'package:test/test.dart';

void main() {
  group('DateOnly Value Object (R5 / format: date estrito)', () {
    test('faz parse de data válida no formato YYYY-MM-DD', () {
      final date = DateOnly.tryParse('2026-10-25');
      expect(date, isNotNull);
      expect(date!.year, 2026);
      expect(date.month, 10);
      expect(date.day, 25);
      expect(date.toString(), '2026-10-25');
      expect(date.toUtcDateTime(), DateTime.utc(2026, 10, 25));
    });

    test('rejeita formato com horário/timestamp (sem truncamento silencioso)', () {
      expect(DateOnly.tryParse('2026-10-25T10:00:00Z'), isNull);
      expect(DateOnly.tryParse('2026-10-25 10:00:00'), isNull);
      expect(DateOnly.tryParse('2026-10-25T00:00:00'), isNull);
    });

    test('rejeita datas inexistentes no calendário (validação de dias do mês)', () {
      expect(DateOnly.tryParse('2026-02-29'), isNull); // 2026 não é bissexto
      expect(DateOnly.tryParse('2026-02-30'), isNull);
      expect(DateOnly.tryParse('2026-04-31'), isNull);
      expect(DateOnly.tryParse('2026-13-01'), isNull);
      expect(DateOnly.tryParse('2026-00-10'), isNull);
      expect(DateOnly.tryParse('2026-05-00'), isNull);
    });

    test('aceita 29 de fevereiro em anos bissextos', () {
      expect(DateOnly.tryParse('2024-02-29'), isNotNull);
      expect(DateOnly.tryParse('2000-02-29'), isNotNull);
      expect(DateOnly.tryParse('1900-02-29'), isNull);
    });

    test('rejeita formatos numéricos parciais e strings vazias', () {
      expect(DateOnly.tryParse(''), isNull);
      expect(DateOnly.tryParse('   '), isNull);
      expect(DateOnly.tryParse('2026-1-1'), isNull);
      expect(DateOnly.tryParse('26-10-25'), isNull);
      expect(DateOnly.tryParse('2026/10/25'), isNull);
    });

    test('igualdade por valor e hashCode', () {
      final d1 = DateOnly.tryParse('2026-10-25');
      final d2 = DateOnly.tryParse('2026-10-25');
      final d3 = DateOnly.tryParse('2026-10-26');

      expect(d1, equals(d2));
      expect(d1.hashCode, equals(d2.hashCode));
      expect(d1, isNot(equals(d3)));
    });
  });
}

