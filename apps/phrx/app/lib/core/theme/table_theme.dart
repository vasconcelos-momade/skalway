import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'pharma_color_tokens.dart';
import 'table_tokens.dart';

@immutable
class TableTheme extends ThemeExtension<TableTheme> {
  const TableTheme({
    required this.headerBackgroundColor,
    required this.headerTextStyle,
    required this.rowHeight,
    required this.dividerColor,
    required this.hoverColor,
    required this.selectedColor,
    required this.zebraEvenColor,
    required this.zebraOddColor,
    this.zebraEnabled = true,
  });

  final Color headerBackgroundColor;
  final TextStyle headerTextStyle;
  final double rowHeight;
  final Color dividerColor;
  final Color hoverColor;
  final Color selectedColor;

  /// Linha par (base da tabela).
  final Color zebraEvenColor;

  /// Linha ímpar — contraste subtil (2–3%).
  final Color zebraOddColor;

  /// Activa zebra striping nas [EnterpriseDataTable]s.
  final bool zebraEnabled;

  factory TableTheme.fromLegacy(
    PharmaTokens tokens, {
    TextTheme? textTheme,
    ColorScheme? scheme,
    PharmaColorTokens? colors,
  }) {
    final theme = textTheme ?? ThemeData().textTheme;
    final isDark = (scheme?.brightness ?? Brightness.light) == Brightness.dark;
    final table = TableTokens.fromPharma(tokens, isDark: isDark);

    return TableTheme(
      headerBackgroundColor: colors?.surfaceContainerLow ?? table.headerBackground,
      headerTextStyle: table.headerStyle(theme, tokens).copyWith(
        color: tokens.textSecondary,
      ),
      rowHeight: table.rowHeightMax,
      dividerColor: colors?.divider ?? table.divider,
      hoverColor: colors?.neutralSubtle ?? table.hover,
      selectedColor: colors?.primarySubtle ?? table.selected,
      zebraEvenColor: table.rowBackground,
      zebraOddColor: colors?.neutralSubtle ?? table.zebraOdd,
      zebraEnabled: true,
    );
  }

  @override
  TableTheme copyWith({
    Color? headerBackgroundColor,
    TextStyle? headerTextStyle,
    double? rowHeight,
    Color? dividerColor,
    Color? hoverColor,
    Color? selectedColor,
    Color? zebraEvenColor,
    Color? zebraOddColor,
    bool? zebraEnabled,
  }) {
    return TableTheme(
      headerBackgroundColor:
          headerBackgroundColor ?? this.headerBackgroundColor,
      headerTextStyle: headerTextStyle ?? this.headerTextStyle,
      rowHeight: rowHeight ?? this.rowHeight,
      dividerColor: dividerColor ?? this.dividerColor,
      hoverColor: hoverColor ?? this.hoverColor,
      selectedColor: selectedColor ?? this.selectedColor,
      zebraEvenColor: zebraEvenColor ?? this.zebraEvenColor,
      zebraOddColor: zebraOddColor ?? this.zebraOddColor,
      zebraEnabled: zebraEnabled ?? this.zebraEnabled,
    );
  }

  @override
  TableTheme lerp(ThemeExtension<TableTheme>? other, double t) {
    if (other is! TableTheme) return this;
    return t < 0.5 ? this : other;
  }
}

extension TableThemeX on BuildContext {
  TableTheme get tableTheme =>
      Theme.of(this).extension<TableTheme>() ??
      TableTheme.fromLegacy(
        Theme.of(this).extension<PharmaTokens>() ??
            PharmaTokens.enterpriseLight(),
        textTheme: Theme.of(this).textTheme,
      );
}
