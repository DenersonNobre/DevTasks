import 'dart:ui';
import 'package:devtasks_app/global/theme/contrast.dart';
import 'package:devtasks_app/global/theme/tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WCAG 2.1 Contrast Calculation', () {
    test('calculates relative luminance according to W3C formula', () {
      // Branco puro = 1.0, Preto puro = 0.0
      expect(relativeLuminance(const Color(0xFFFFFFFF)), closeTo(1.0, 0.001));
      expect(relativeLuminance(const Color(0xFF000000)), closeTo(0.0, 0.001));
    });

    test('calculates contrast ratio between extremes', () {
      final white = const Color(0xFFFFFFFF);
      final black = const Color(0xFF000000);

      // Branco x Preto deve atingir 21:1 máximo
      expect(contrastRatio(white, black), closeTo(21.0, 0.1));
      // Mesma cor deve atingir 1:1 mínimo
      expect(contrastRatio(white, white), closeTo(1.0, 0.001));
      expect(contrastRatio(black, black), closeTo(1.0, 0.001));
    });

    test('verifies WCAG AA thresholds helper', () {
      expect(meetsWcagAaNormalText(4.5), isTrue);
      expect(meetsWcagAaNormalText(4.49), isFalse);
      expect(meetsWcagAaLargeText(3.0), isTrue);
      expect(meetsWcagAaLargeText(2.99), isFalse);
    });
  });

  group('Design Tokens Contrast Compliance (RNF-05 / DESIGN.md §2.1 & §6)', () {
    test('Light Theme: primary text against background and surface exceeds 7:1', () {
      final textRatioOnBg = contrastRatio(AppColors.lightTextMain, AppColors.lightBackground);
      final textRatioOnSurface = contrastRatio(AppColors.lightTextMain, AppColors.lightSurface);

      expect(textRatioOnBg, greaterThanOrEqualTo(7.0));
      expect(textRatioOnSurface, greaterThanOrEqualTo(7.0));
      expect(meetsWcagAaNormalText(textRatioOnBg), isTrue);
    });

    test('Light Theme: muted text against background and surface satisfies WCAG AA (>= 4.5:1)', () {
      final mutedRatioOnBg = contrastRatio(AppColors.lightTextMuted, AppColors.lightBackground);
      final mutedRatioOnSurface = contrastRatio(AppColors.lightTextMuted, AppColors.lightSurface);

      expect(mutedRatioOnBg, greaterThanOrEqualTo(4.5));
      expect(mutedRatioOnSurface, greaterThanOrEqualTo(4.5));
      expect(meetsWcagAaNormalText(mutedRatioOnSurface), isTrue);
    });

    test('Light Theme: primary deep on surface satisfies normal text AA (>= 4.5:1)', () {
      // DESIGN.md §2.1: para texto roxo sobre branco, usar color-primary-deep (>= 4.5:1)
      final deepRatio = contrastRatio(AppColors.primaryDeep, AppColors.lightSurface);
      expect(deepRatio, greaterThanOrEqualTo(4.5));
      expect(meetsWcagAaNormalText(deepRatio), isTrue);
    });

    test('Light Theme: white text on primary button satisfies large text / graphical UI AA (>= 3.0:1)', () {
      // DESIGN.md §2.1 nota: #8575F8 sobre branco / branco sobre #8575F8 >= 3.0:1 para botões
      final buttonRatio = contrastRatio(const Color(0xFFFFFFFF), AppColors.primary);
      expect(buttonRatio, greaterThanOrEqualTo(3.0));
      expect(meetsWcagAaLargeText(buttonRatio), isTrue);
    });

    test('Dark Theme: text main against dark background exceeds 7:1', () {
      final darkTextRatio = contrastRatio(AppColors.darkTextMain, AppColors.darkBackground);
      expect(darkTextRatio, greaterThanOrEqualTo(7.0));
      expect(meetsWcagAaNormalText(darkTextRatio), isTrue);
    });

    test('Dark Theme: muted text against dark surface satisfies WCAG AA (>= 4.5:1)', () {
      final darkMutedRatio = contrastRatio(AppColors.darkTextMuted, AppColors.darkSurface);
      expect(darkMutedRatio, greaterThanOrEqualTo(4.5));
      expect(meetsWcagAaNormalText(darkMutedRatio), isTrue);
    });
  });
}

