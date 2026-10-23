import 'package:flutter/material.dart';

/// Tokens semânticos de cores do DevTasks.
///
/// Todas as constantes possuem origem e uso rastreáveis no DESIGN.md (§2.1 e §6).
abstract final class AppColors {
  // --- Paleta Semântica Base (DESIGN.md §2.1) ---

  /// `color-primary` [medido faixa #8068E8–#8878F8]: Botões primários, links ativos, marca.
  static const Color primary = Color(0xFF8575F8);

  /// `color-primary-deep` [medido]: Hover/foco de primário e texto roxo sobre branco (>= 4.5:1).
  static const Color primaryDeep = Color(0xFF7058D0);

  /// `color-primary-soft` [estimado]: Fundo sutil de badge e área ativa.
  static const Color primarySoft = Color(0xFFEEEBFF);

  /// `color-navy` [medido]: Cabeçalhos de módulo, títulos fortes, superfícies dark.
  static const Color navy = Color(0xFF283848);

  /// `color-text-main` [medido faixa #102030–#182838]: Texto primário do tema claro (>= 7:1).
  static const Color lightTextMain = Color(0xFF1A2433);

  /// `color-text-muted` [estimado]: Rótulos, legendas, metadados claro (>= 4.5:1).
  static const Color lightTextMuted = Color(0xFF6B7280);

  /// `color-background` [medido]: Fundo geral da aplicação claro.
  static const Color lightBackground = Color(0xFFFAFAFB);

  /// `color-surface` [medido]: Cards, modais, painéis claro.
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// `color-border` [medido]: Divisores, contornos de card/inputs claro.
  static const Color lightBorder = Color(0xFFE3E4E8);

  /// `color-success` [estimado]: Concluído, validação positiva.
  static const Color success = Color(0xFF2FA36B);

  /// `color-error` [estimado]: Erros, ações destrutivas, prioridade alta.
  static const Color error = Color(0xFFE5484D);

  /// `color-warning` [estimado]: Prioridade média, avisos.
  static const Color warning = Color(0xFFE5A100);

  /// `color-info` [estimado]: Em andamento, prioridade baixa.
  static const Color info = Color(0xFF3B82F6);

  // --- Tema Escuro Semântico (DESIGN.md §6) ---

  /// `background dark` [DESIGN.md §6]: Fundo do tema escuro (#0F141B).
  static const Color darkBackground = Color(0xFF0F141B);

  /// `surface dark` [DESIGN.md §6]: Cards e painéis no tema escuro (#1A212C).
  static const Color darkSurface = Color(0xFF1A212C);

  /// `navy dark` [DESIGN.md §6]: Cabeçalhos no tema escuro (#232E3D).
  static const Color darkNavy = Color(0xFF232E3D);

  /// `text-main dark` [DESIGN.md §6]: Texto primário no tema escuro (#E6EAF0).
  static const Color darkTextMain = Color(0xFFE6EAF0);

  /// `text-muted dark` [DESIGN.md §6]: Texto secundário no tema escuro (#94A3B8).
  static const Color darkTextMuted = Color(0xFF94A3B8);

  /// `border dark` [DESIGN.md §6]: Divisores no tema escuro (#2A3447).
  static const Color darkBorder = Color(0xFF2A3447);
}

/// Raios de borda padronizados (DESIGN.md §2.4).
abstract final class AppRadii {
  /// `r-sm`: 8px (badges, inputs, botões)
  static const double sm = 8.0;

  /// `r-md`: 12px (cards, contêineres médios)
  static const double md = 12.0;

  /// `r-lg`: 16px (modais, colunas kanban)
  static const double lg = 16.0;

  /// `r-full`: 999px (pills, avatares circulares)
  static const double full = 999.0;
}

/// Espaçamentos do grid de 4px (DESIGN.md §2.4).
abstract final class AppSpacing {
  /// 4px
  static const double space1 = 4.0;

  /// 8px
  static const double space2 = 8.0;

  /// 12px
  static const double space3 = 12.0;

  /// 16px
  static const double space4 = 16.0;

  /// 24px
  static const double space6 = 24.0;

  /// 32px
  static const double space8 = 32.0;
}

