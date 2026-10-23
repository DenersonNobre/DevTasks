import 'dart:math' as math;
import 'dart:ui';

/// Calcula a luminância relativa de uma cor de acordo com a especificação W3C WCAG 2.1.
///
/// https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
double relativeLuminance(Color color) {
  double channelLuminance(double channel) {
    if (channel <= 0.04045) {
      return channel / 12.92;
    } else {
      return math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
    }
  }

  // Color.r, g, b no Flutter moderno são doubles normalizados de 0.0 a 1.0.
  final r = channelLuminance(color.r);
  final g = channelLuminance(color.g);
  final b = channelLuminance(color.b);

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Calcula a razão de contraste entre duas cores de acordo com o W3C WCAG 2.1.
///
/// Retorna um valor entre 1.0 (mesma cor) e 21.0 (preto e branco).
/// https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio
double contrastRatio(Color foreground, Color background) {
  final l1 = relativeLuminance(foreground);
  final l2 = relativeLuminance(background);

  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);

  return (lighter + 0.05) / (darker + 0.05);
}

/// Avalia conformidade WCAG 2.1 AA para texto normal (< 18pt / < 14pt bold).
///
/// Threshold exigido: >= 4.5:1.
bool meetsWcagAaNormalText(double ratio) => ratio >= 4.5;

/// Avalia conformidade WCAG 2.1 AA para texto grande (>= 18pt / >= 14pt bold)
/// e componentes de interface gráfica essenciais.
///
/// Threshold exigido: >= 3.0:1.
bool meetsWcagAaLargeText(double ratio) => ratio >= 3.0;

