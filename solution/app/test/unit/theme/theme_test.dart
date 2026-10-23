import 'package:devtasks_app/global/theme/app_theme.dart';
import 'package:devtasks_app/global/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme Configuration (RNF-06 / RNF-07 / DESIGN.md §2 & §6)', () {
    test('light theme produces valid ThemeData with Brightness.light', () {
      final theme = AppTheme.light();

      expect(theme.brightness, equals(Brightness.light));
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, equals(Brightness.light));
      expect(theme.colorScheme.primary, equals(AppColors.primary));
      expect(theme.colorScheme.surface, equals(AppColors.lightSurface));
      expect(theme.scaffoldBackgroundColor, equals(AppColors.lightBackground));
      expect(theme.textTheme.bodyMedium?.fontFamily, equals('Inter'));
    });

    test('dark theme produces valid ThemeData with Brightness.dark', () {
      final theme = AppTheme.dark();

      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, equals(Brightness.dark));
      expect(theme.colorScheme.primary, equals(AppColors.primary));
      expect(theme.colorScheme.surface, equals(AppColors.darkSurface));
      expect(theme.scaffoldBackgroundColor, equals(AppColors.darkBackground));
      expect(theme.textTheme.bodyMedium?.fontFamily, equals('Inter'));
    });

    test('design tokens adhere to DESIGN.md canonical values', () {
      // Light tokens (§2.1)
      expect(AppColors.primary, equals(const Color(0xFF8575F8)));
      expect(AppColors.primaryDeep, equals(const Color(0xFF7058D0)));
      expect(AppColors.primarySoft, equals(const Color(0xFFEEEBFF)));
      expect(AppColors.navy, equals(const Color(0xFF283848)));
      expect(AppColors.lightTextMain, equals(const Color(0xFF1A2433)));
      expect(AppColors.lightTextMuted, equals(const Color(0xFF6B7280)));
      expect(AppColors.lightBackground, equals(const Color(0xFFFAFAFB)));
      expect(AppColors.lightSurface, equals(const Color(0xFFFFFFFF)));
      expect(AppColors.lightBorder, equals(const Color(0xFFE3E4E8)));
      expect(AppColors.success, equals(const Color(0xFF2FA36B)));
      expect(AppColors.error, equals(const Color(0xFFE5484D)));
      expect(AppColors.warning, equals(const Color(0xFFE5A100)));
      expect(AppColors.info, equals(const Color(0xFF3B82F6)));

      // Dark tokens (§6)
      expect(AppColors.darkBackground, equals(const Color(0xFF0F141B)));
      expect(AppColors.darkSurface, equals(const Color(0xFF1A212C)));
      expect(AppColors.darkNavy, equals(const Color(0xFF232E3D)));
      expect(AppColors.darkTextMain, equals(const Color(0xFFE6EAF0)));
      expect(AppColors.darkBorder, equals(const Color(0xFF2A3447)));

      // Radii tokens (§2.4)
      expect(AppRadii.sm, equals(8.0));
      expect(AppRadii.md, equals(12.0));
      expect(AppRadii.lg, equals(16.0));
      expect(AppRadii.full, equals(999.0));

      // Spacing tokens (§2.4)
      expect(AppSpacing.space1, equals(4.0));
      expect(AppSpacing.space2, equals(8.0));
      expect(AppSpacing.space3, equals(12.0));
      expect(AppSpacing.space4, equals(16.0));
      expect(AppSpacing.space6, equals(24.0));
      expect(AppSpacing.space8, equals(32.0));
    });
  });
}

