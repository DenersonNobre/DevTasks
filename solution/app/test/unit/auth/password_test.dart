// solution/app/test/unit/auth/password_test.dart
// Unit tests for the Password value object (UC-01.01 / password policy).

import 'package:devtasks_app/modules/auth/domain/password.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Password.parse', () {
    test('rejects a value shorter than 12 characters', () {
      final result = Password.parse('curta1!A');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.field, 'password');
    });

    test('rejects a value longer than 128 characters', () {
      final result = Password.parse('${'A' * 129}1a');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.field, 'password');
    });

    test('rejects a value without an uppercase letter', () {
      final result = Password.parse('semmaiuscula1');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.field, 'password');
    });

    test('rejects a value without a digit', () {
      final result = Password.parse('semdigitoABC');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.field, 'password');
    });

    test('rejects a value without a lowercase letter', () {
      final result = Password.parse('F0RTRE#PASS2026');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.field, 'password');
    });

    test('accepts a policy compliant password', () {
      final result = Password.parse('F0rtress!Pass2026');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.value, 'F0rtress!Pass2026');
    });

    test('never exposes the secret through toString', () {
      final password = Password.parse('F0rtress!Pass2026').valueOrNull;

      expect(password.toString(), isNot(contains('F0rtress!Pass2026')));
      expect(password.toString(), 'Password(***)');
    });

    test('compares by value (value object semantics)', () {
      final first = Password.parse('F0rtress!Pass2026').valueOrNull;
      final second = Password.parse('F0rtress!Pass2026').valueOrNull;
      final third = Password.parse('F0rtress!Pass2027').valueOrNull;

      expect(first, equals(second));
      expect(first.hashCode, equals(second.hashCode));
      expect(first, isNot(equals(third)));
    });
  });
}
