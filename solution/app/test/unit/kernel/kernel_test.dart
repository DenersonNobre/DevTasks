import 'package:devtasks_app/global/kernel/.kernel.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeClock implements IClock {
  final DateTime _fixed;
  FakeClock(this._fixed);

  @override
  DateTime now() => _fixed;

  @override
  DateTime today() => DateTime(_fixed.year, _fixed.month, _fixed.day);
}

void main() {
  group('IResult<T, F>', () {
    test('Success encapsula valor e reage a fold/map', () {
      final IResult<int, IFailure> result = Success(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.valueOrNull, equals(42));
      expect(result.failureOrNull, isNull);

      final folded = result.fold(
        (val) => 'val: $val',
        (fail) => 'fail: ${fail.code}',
      );
      expect(folded, equals('val: 42'));

      final mapped = result.map((val) => val * 2);
      expect(mapped.valueOrNull, equals(84));

      final flatMapped = result.flatMap((val) => Success('num: $val'));
      expect(flatMapped.valueOrNull, equals('num: 42'));
    });

    test('Failure encapsula erro tipado e não executa map', () {
      final failure = ValidationFailure('Campo obrigatório', 'title');
      final IResult<int, IFailure> result = Failure(failure);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, equals(failure));

      final folded = result.fold(
        (val) => 'val: $val',
        (fail) => 'fail: ${fail.code}',
      );
      expect(folded, equals('fail: ERR_VALIDATION'));

      final mapped = result.map((val) => val * 2);
      expect(mapped.isFailure, isTrue);
      expect(mapped.failureOrNull?.code, equals('ERR_VALIDATION'));
    });
  });

  group('Taxonomia de Falhas (SPEC §6)', () {
    test('todas as falhas de negócio reportam códigos canônicos da SPEC', () {
      expect(ValidationFailure('inv').code, equals('ERR_VALIDATION'));
      expect(NotAuthenticatedFailure().code, equals('ERR_NOT_AUTHENTICATED'));
      expect(InvalidCredentialsFailure().code, equals('ERR_INVALID_CREDENTIALS'));
      expect(EmailAlreadyTakenFailure().code, equals('ERR_EMAIL_ALREADY_TAKEN'));
      expect(NotFoundFailure().code, equals('ERR_NOT_FOUND'));
      expect(InsufficientRoleFailure().code, equals('ERR_INSUFFICIENT_ROLE'));
      expect(ProjectArchivedFailure().code, equals('ERR_PROJECT_ARCHIVED'));
      expect(InvalidAssigneeFailure().code, equals('ERR_INVALID_ASSIGNEE'));
      expect(MemberAlreadyExistsFailure().code, equals('ERR_MEMBER_ALREADY_EXISTS'));
      expect(ConcurrentModificationFailure().code, equals('ERR_CONCURRENT_MODIFICATION'));
      expect(InfraFailure('db down').code, equals('ERR_INFRA_FAILURE'));
    });
  });

  group('Value Objects Base', () {
    test('NonEmptyString valida string não-vazia', () {
      final valid = NonEmptyString.create(' Tarefa importante ');
      expect(valid.isSuccess, isTrue);
      expect(valid.valueOrNull?.value, equals('Tarefa importante'));

      final empty = NonEmptyString.create('   ');
      expect(empty.isFailure, isTrue);
      expect(empty.failureOrNull?.code, equals('ERR_VALIDATION'));
    });

    test('Identificadores tipados possuem igualdade por valor', () {
      final u1 = UserId(1);
      final u2 = UserId(1);
      final u3 = UserId(2);

      expect(u1, equals(u2));
      expect(u1 == u3, isFalse);
      expect(u1.hashCode, equals(u2.hashCode));
      expect(u1.toString(), contains('UserId(1)'));

      final w1 = WorkspaceId(10);
      final p1 = ProjectId(20);
      final t1 = TaskId(30);
      final c1 = CommentId(40);

      expect(w1.value, equals(10));
      expect(p1.value, equals(20));
      expect(t1.value, equals(30));
      expect(c1.value, equals(40));
    });

    test('DateOnly opera estritamente sem hora nem ruído de timezone', () {
      final dateRes = DateOnly.parse('2026-10-25');
      expect(dateRes.isSuccess, isTrue);

      final date = dateRes.valueOrNull!;
      expect(date.year, equals(2026));
      expect(date.month, equals(10));
      expect(date.day, equals(25));
      expect(date.toString(), equals('2026-10-25'));

      final invalidRes = DateOnly.parse('invalid-date');
      expect(invalidRes.isFailure, isTrue);

      final clockToday = FakeClock(DateTime(2026, 10, 25, 14, 30));
      final clockPast = FakeClock(DateTime(2026, 10, 26, 8, 00));
      final clockFuture = FakeClock(DateTime(2026, 10, 24, 20, 00));

      expect(date.isToday(clockToday), isTrue);
      expect(date.isOverdue(clockPast), isTrue);
      expect(date.isOverdue(clockFuture), isFalse);
    });
  });

  group('IClock / SystemClock', () {
    test('SystemClock retorna data e hora atual sem falhas', () {
      final clock = SystemClock();
      final now = clock.now();
      final today = clock.today();

      expect(now.year, greaterThanOrEqualTo(2026));
      expect(today.hour, equals(0));
      expect(today.minute, equals(0));
      expect(today.second, equals(0));
    });
  });
}

