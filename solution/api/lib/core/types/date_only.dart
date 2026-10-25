// solution/api/lib/core/types/date_only.dart
// Tipo estrito de data de calendário (format: date / ISO-8601 YYYY-MM-DD).
// Invariante: rejeita horário/timestamp, formatos incompletos e datas inexistentes.

/// Data de calendário (formato estrito `YYYY-MM-DD` / OpenAPI 3.1 `format: date`).
final class DateOnly {
  const DateOnly._(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  static final RegExp _format = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// Tenta fazer o parse de uma string no formato estrito `YYYY-MM-DD`.
  /// Rejeita partes de horário/timestamp (`2026-10-25T10:00:00Z`) e dias inexistentes.
  static DateOnly? tryParse(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (!_format.hasMatch(trimmed)) return null;

    final parts = trimmed.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final d = int.parse(parts[2]);

    if (m < 1 || m > 12) return null;
    if (d < 1 || d > _daysInMonth(y, m)) return null;

    return DateOnly._(y, m, d);
  }

  static int _daysInMonth(int year, int month) {
    return switch (month) {
      1 || 3 || 5 || 7 || 8 || 10 || 12 => 31,
      4 || 6 || 9 || 11 => 30,
      2 => _isLeapYear(year) ? 29 : 28,
      _ => 0,
    };
  }

  static bool _isLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);

  DateTime toUtcDateTime() => DateTime.utc(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateOnly &&
          year == other.year &&
          month == other.month &&
          day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);
}

