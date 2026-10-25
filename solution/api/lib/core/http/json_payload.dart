// solution/api/lib/core/http/json_payload.dart
// Helpers seguros para leitura e validação de tipos em payloads JSON (R4/R5).
// Garante retorno de 400 ERR_VALIDATION para tipos primitivos trocados, evitando vazamento de 500.

import '../types/date_only.dart';
import 'api_exception.dart';

/// Helpers de extração tipada de campos em mapas JSON.
abstract final class JsonPayload {
  /// Extrai string obrigatória, lançando [ApiException.badRequest] se ausente ou não-string.
  static String requireString(
    Map<String, Object?> map,
    String key, {
    int? minLength,
    int? maxLength,
  }) {
    if (!map.containsKey(key)) {
      throw ApiException.badRequest('O campo $key é obrigatório.', field: key);
    }
    final val = map[key];
    if (val is! String) {
      throw ApiException.badRequest('O campo $key deve ser uma string.', field: key);
    }
    final trimmed = val.trim();
    if (minLength != null && trimmed.length < minLength) {
      throw ApiException.badRequest(
        'O campo $key deve ter no mínimo $minLength caractere(s).',
        field: key,
      );
    }
    if (maxLength != null && trimmed.length > maxLength) {
      throw ApiException.badRequest(
        'O campo $key deve ter no máximo $maxLength caracteres.',
        field: key,
      );
    }
    return trimmed;
  }

  /// Extrai string opcional. Retorna null se ausente ou explicitamente null.
  /// Lança [ApiException.badRequest] se presente e não for string.
  static String? optionalString(
    Map<String, Object?> map,
    String key, {
    int? maxLength,
  }) {
    if (!map.containsKey(key)) return null;
    final val = map[key];
    if (val == null) return null;
    if (val is! String) {
      throw ApiException.badRequest('O campo $key deve ser uma string.', field: key);
    }
    final trimmed = val.trim();
    if (maxLength != null && trimmed.length > maxLength) {
      throw ApiException.badRequest(
        'O campo $key deve ter no máximo $maxLength caracteres.',
        field: key,
      );
    }
    return trimmed;
  }

  /// Extrai número (double) opcional. Retorna null se ausente ou explicitamente null.
  /// Lança [ApiException.badRequest] se presente e não for num.
  static double? optionalDouble(Map<String, Object?> map, String key) {
    if (!map.containsKey(key)) return null;
    final val = map[key];
    if (val == null) return null;
    if (val is! num) {
      throw ApiException.badRequest('O campo $key deve ser um número.', field: key);
    }
    return val.toDouble();
  }

  /// Extrai data de calendário opcional (formato YYYY-MM-DD estrito).
  /// Retorna null se ausente ou explicitamente null.
  /// Lança [ApiException.badRequest] se não for string ou não for YYYY-MM-DD válido.
  static DateOnly? optionalDate(Map<String, Object?> map, String key) {
    if (!map.containsKey(key)) return null;
    final val = map[key];
    if (val == null) return null;
    if (val is! String) {
      throw ApiException.badRequest(
        'O campo $key deve ser uma string no formato YYYY-MM-DD.',
        field: key,
      );
    }
    final parsed = DateOnly.tryParse(val);
    if (parsed == null) {
      throw ApiException.badRequest(
        'Data de vencimento inválida (formato exigido: YYYY-MM-DD).',
        field: key,
      );
    }
    return parsed;
  }
}

