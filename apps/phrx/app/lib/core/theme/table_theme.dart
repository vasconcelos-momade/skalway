import 'package:flutter/material.dart';

import 'design_metrics.dart';
import 'design_tokens.dart';
import 'typography.dart';

@immutable
class TableTheme extends ThemeExtension<TableTheme> {
  const TableTheme({
    required this.headerBackgroundColor,
    required this.headerTextStyle,
    required this.rowHeight,
    required this.dividerColor,
    required this.hoverColor,
    required this.selectedColor,
  });

  final Color headerBackgroundColor;
  final TextStyle headerTextStyle;
  final double rowHeight;
  final Color dividerColor;
  final Color hoverColor;
  final Color selectedColor;

  factory TableTheme.fromLegacy(PharmaTokens tokens, {TextTheme? textTheme}) {
    final theme = textTheme ?? ThemeData().textTheme;
    return TableTheme(
      headerBackgroundColor: tokens.bgSecondary,
      headerTextStyle: theme.erpTableHeader.copyWith(
        color: tokens.textPrimary,
      ),
      rowHeight: DesignMetrics.tableRowHeightMax,
      dividerColor: tokens.border,
      hoverColor: tokens.cardHover,
      selectedColor: tokens.brandGreen.withValues(alpha: 0.12),
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
  }) {
    return TableTheme(
      headerBackgroundColor: headerBackgroundColor ?? this.headerBackgroundColor,
      headerTextStyle: headerTextStyle ?? this.headerTextStyle,
      rowHeight: rowHeight ?? this.rowHeight,
      dividerColor: dividerColor ?? this.dividerColor,
      hoverColor: hoverColor ?? this.hoverColor,
      selectedColor: selectedColor ?? this.selectedColor,
    );
  }

  @override
  TableTheme lerp(ThemeExtension<TableTheme>? other, double t) {
    if (other is! TableTheme) return this;
    return t < 0.5 ? this : other;
  }

  static double? lerpDouble(num? a, num? b, double t) {
    if (a == null && b == null) return null;
    a ??= 0.0;
    b ??= 0.0;
    return a + (b - a) * t;
  }
}

extension TableThemeX on BuildContext {
  TableTheme get tableTheme =>
      Theme.of(this).extension<TableTheme>() ??
      TableTheme.fromLegacy(
        Theme.of(this).extension<PharmaTokens>() ?? PharmaTokens.enterpriseLight(),
        textTheme: Theme.of(this).textTheme,
      );
}
