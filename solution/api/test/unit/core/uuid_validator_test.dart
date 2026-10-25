// solution/api/test/unit/core/uuid_validator_test.dart
// Testes unitários do validador de UUID (Achado A-1 da auditoria).

import 'package:devtasks_api/core/types/uuid_validator.dart';
import 'package:test/test.dart';

void main() {
  group('UuidValidator (A-1)', () {
    test('aceita UUIDs válidos em minúsculas e maiúsculas', () {
      expect(UuidValidator.isValid('123e4567-e89b-12d3-a456-426614174000'), isTrue);
      expect(UuidValidator.isValid('123E4567-E89B-12D3-A456-426614174000'), isTrue);
      expect(UuidValidator.isValid('00000000-0000-0000-0000-000000000000'), isTrue);
    });

    test('rejeita strings que não são UUIDs', () {
      expect(UuidValidator.isValid(null), isFalse);
      expect(UuidValidator.isValid(''), isFalse);
      expect(UuidValidator.isValid('   '), isFalse);
      expect(UuidValidator.isValid('nao-e-uuid'), isFalse);
      expect(UuidValidator.isValid('12345'), isFalse);
      expect(UuidValidator.isValid('123e4567-e89b-12d3-a456-42661417400'), isFalse); // 1 dígito a menos
      expect(UuidValidator.isValid('123e4567-e89b-12d3-a456-4266141740000'), isFalse); // 1 dígito a mais
      expect(UuidValidator.isValid('123e4567e89b12d3a456426614174000'), isFalse); // sem hífens
      expect(UuidValidator.isValid('123e4567-e89b-12d3-a456-42661417400g'), isFalse); // 'g' não é hex
    });
  });
}

