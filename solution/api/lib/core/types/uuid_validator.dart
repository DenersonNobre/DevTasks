// solution/api/lib/core/types/uuid_validator.dart
// Validador de formato UUID v4/v1 (RFC 4122) para IDs na fronteira e repositórios (A-1).

/// Utilitário puro de validação de formato canônico de UUID.
abstract final class UuidValidator {
  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Retorna `true` se [value] for uma string não-nula e casar estritamente com o formato de UUID.
  static bool isValid(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    return _uuidRegex.hasMatch(trimmed);
  }
}

