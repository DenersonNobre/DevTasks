// solution/app/test/unit/auth/email_test.dart
// Unit tests for the Email value object (UC-01.01 / INV-08 input hygiene).

import 'package:devtasks_app/modules/auth/domain/email.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Email.parse', () {
    test('normalizes surrounding spaces and casing', () {
      final result = Email.parse('  BIA@Ex.COM ');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.value, 'bia@ex.com');
      expect(result.valueOrNull.toString(), 'bia@ex.com');
    });

    test('rejects input without at sign with a validation failure on email', () {
      final result = Email.parse('sem-arroba');

      expect(result.isFailure, isTrue);
      final failure = result.failureOrNull;
      expect(failure, isNotNull);
      expect(failure!.field, 'email');
      expect(failure.code, 'ERR_VALIDATION');
    });

    test('rejects input without a top level domain', () {
      final result = Email.parse('a@b');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.field, 'email');
    });

    test('rejects empty input', () {
      final result = Email.parse('   ');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.field, 'email');
    });

    test('compares by normalized value (value object semantics)', () {
      final first = Email.parse('Bia@Ex.com ').valueOrNull;
      final second = Email.parse(' bia@ex.COM').valueOrNull;

      expect(first, equals(second));
      expect(first.hashCode, equals(second.hashCode));
    });
  });
}
