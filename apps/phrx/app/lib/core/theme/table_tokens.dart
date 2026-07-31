import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'spacing_tokens.dart';
import 'typography.dart';

/// Tokens específicos de Data Table (padrão Trae).
///
/// - Header ligeiramente elevado (Surface 3)
/// - Zebra extremamente subtil (2–3%)
/// - Linhas discretas
/// - Maior densidade
/// - Padding consistente
/// - Sem caixas pesadas
@immutable
class TableTokens {
  const TableTokens({
    required this.headerBackground,
    required this.rowBackground,
    required this.zebraOdd,
    required this.divider,
    required this.hover,
    required this.selected,
    required this.rowHeightMin,
    required this.rowHeightMax,
    required this.cellPaddingH,
    required this.cellPaddingV,
    required this.columnSpacing,
  });

  final Color headerBackground;
  final Color rowBackground;
  final Color zebraOdd;
  final Color divider;
  final Color hover;
  final Color selected;
  final double rowHeightMin;
  final double rowHeightMax;
  final double cellPaddingH;
  final double cellPaddingV;
  final double columnSpacing;

  /// Densidade Trae — linhas compactas.
  static const double _rowMin = 52;
  static const double _rowMax = 56;

  factory TableTokens.fromPharma(
    PharmaTokens tokens, {
    required bool isDark,
  }) {
    final base = tokens.surface2;
    final odd = Color.alphaBlend(
      tokens.textPrimary.withValues(alpha: isDark ? 0.025 : 0.02),
      base,
    );

    return TableTokens(
      headerBackground: tokens.surface3,
      rowBackground: base,
      zebraOdd: odd,
      divider: tokens.border,
      hover: tokens.cardHover,
      selected: tokens.brandGreen.withValues(alpha: 0.12),
      rowHeightMin: _rowMin,
      rowHeightMax: _rowMax,
      cellPaddingH: SpacingTokens.md,
      cellPaddingV: SpacingTokens.sm,
      columnSpacing: SpacingTokens.lg,
    );
  }

  TextStyle headerStyle(TextTheme theme, PharmaTokens tokens) =>
      theme.erpTableHeader.copyWith(color: tokens.textPrimary);

  TextStyle cellStyle(TextTheme theme, PharmaTokens tokens) =>
      theme.erpTableSecondary.copyWith(color: tokens.textPrimary);
}

extension TableTokensX on BuildContext {
  TableTokens get tableTokens {
    final tokens = pharmaTokens;
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return TableTokens.fromPharma(tokens, isDark: isDark);
  }
}
