// solution/app/lib/global/kernel/value_objects.dart
// Value Objects imutáveis fundamentais do domínio (F0.7 / UC-00.07)

import 'clock.dart';
import 'failures.dart';
import 'result.dart';

/// Base para identificadores fortemente tipados.
abstract class IEntityId<T> {
  final T value;

  const IEntityId(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IEntityId<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '$runtimeType($value)';
}

/// Alias para manter compatibilidade com implementações existentes.
typedef EntityId<T> = IEntityId<T>;

/// Identificador de Usuário (UUID — `D-08`).
class UserId extends EntityId<String> {
  const UserId(super.value);
}

/// Identificador de Workspace (UUID — `D-08`).
class WorkspaceId extends EntityId<String> {
  const WorkspaceId(super.value);
}

/// Identificador de Projeto (UUID — `D-08`).
class ProjectId extends EntityId<String> {
  const ProjectId(super.value);
}

/// Identificador de Tarefa.
class TaskId extends EntityId<int> {
  const TaskId(super.value);
}

/// Identificador de Comentário.
class CommentId extends EntityId<int> {
  const CommentId(super.value);
}

/// String não-vazia e sanitizada (trimmed).
class NonEmptyString {
  final String value;

  const NonEmptyString._(this.value);

  static IResult<NonEmptyString, ValidationFailure> create(
    String? input, [
    String fieldName = 'string',
  ]) {
    if (input == null) {
      return Failure(ValidationFailure('$fieldName não pode ser nulo.', fieldName));
    }
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return Failure(ValidationFailure('$fieldName não pode ser vazio.', fieldName));
    }
    return Success(NonEmptyString._(trimmed));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NonEmptyString &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Representa uma data pura sem componente de hora nem distorções de fuso horário (YYYY-MM-DD).
class DateOnly implements Comparable<DateOnly> {
  final int year;
  final int month;
  final int day;

  const DateOnly(this.year, this.month, this.day);

  factory DateOnly.fromDateTime(DateTime dt) => DateOnly(dt.year, dt.month, dt.day);

  static IResult<DateOnly, ValidationFailure> parse(String input, [String fieldName = 'date']) {
    final trimmed = input.trim();
    final regex = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
    final match = regex.firstMatch(trimmed);

    if (match == null) {
      return Failure(ValidationFailure(
        '$fieldName deve seguir o formato YYYY-MM-DD.',
        fieldName,
      ));
    }

    final y = int.parse(match.group(1)!);
    final m = int.parse(match.group(2)!);
    final d = int.parse(match.group(3)!);

    if (m < 1 || m > 12 || d < 1 || d > 31) {
      return Failure(ValidationFailure('$fieldName contém valores fora do intervalo válido.', fieldName));
    }

    final parsedDate = DateTime.utc(y, m, d);
    if (parsedDate.year != y || parsedDate.month != m || parsedDate.day != d) {
      return Failure(ValidationFailure('$fieldName representa uma data de calendário inexistente.', fieldName));
    }

    return Success(DateOnly(y, m, d));
  }

  bool isBefore(DateOnly other) => compareTo(other) < 0;
  bool isAfter(DateOnly other) => compareTo(other) > 0;

  DateTime toDateTime() => DateTime.utc(year, month, day);

  bool isToday(IClock clock) {
    final t = DateOnly.fromDateTime(clock.today());
    return this == t;
  }

  bool isOverdue(IClock clock) {
    final t = DateOnly.fromDateTime(clock.today());
    return isBefore(t);
  }

  DateTime toDateTimeUtc() => DateTime.utc(year, month, day);

  @override
  int compareTo(DateOnly other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateOnly &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

