// solution/app/lib/global/kernel/result.dart
// Padrão IResult tipado (F0.7 / UC-00.07 / D-ENG do oráculo)

/// Representa a união discriminada entre Sucesso [Success] e Falha esperada [Failure].
sealed class IResult<T, F> {
  const IResult();

  bool get isSuccess => this is Success<T, F>;
  bool get isFailure => this is Failure<T, F>;

  T? get valueOrNull => switch (this) {
        Success<T, F>(value: final v) => v,
        Failure<T, F>() => null,
      };

  F? get failureOrNull => switch (this) {
        Success<T, F>() => null,
        Failure<T, F>(failure: final f) => f,
      };

  R fold<R>(
    R Function(T value) onSuccess,
    R Function(F failure) onFailure,
  ) {
    return switch (this) {
      Success<T, F>(value: final v) => onSuccess(v),
      Failure<T, F>(failure: final f) => onFailure(f),
    };
  }

  IResult<R, F> map<R>(R Function(T value) fn) {
    return switch (this) {
      Success<T, F>(value: final v) => Success<R, F>(fn(v)),
      Failure<T, F>(failure: final f) => Failure<R, F>(f),
    };
  }

  IResult<T, R> mapFailure<R>(R Function(F failure) fn) {
    return switch (this) {
      Success<T, F>(value: final v) => Success<T, R>(v),
      Failure<T, F>(failure: final f) => Failure<T, R>(fn(f)),
    };
  }

  IResult<R, F> flatMap<R>(IResult<R, F> Function(T value) fn) {
    return switch (this) {
      Success<T, F>(value: final v) => fn(v),
      Failure<T, F>(failure: final f) => Failure<R, F>(f),
    };
  }
}

final class Success<T, F> extends IResult<T, F> {
  final T value;
  const Success(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T, F> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

final class Failure<T, F> extends IResult<T, F> {
  final F failure;
  const Failure(this.failure);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T, F> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Failure($failure)';
}

