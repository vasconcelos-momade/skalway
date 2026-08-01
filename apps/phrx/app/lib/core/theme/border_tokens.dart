import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tokens de borda — 1px, baixo contraste, sem bordas pesadas.
abstract final class BorderTokens {
  BorderTokens._();

  /// Espessura canónica (1px).
  static const double width = 1;

  /// Indicador lateral de item activo (sidebar / nav).
  static const double indicator = 3;

  static Color defaultFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? AppColorsDark.border
          : AppColorsLight.border;

  static Color subtleFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? AppColorsDark.borderSubtle
          : AppColorsLight.borderSubtle;

  static BorderSide side(Color color, {double width = BorderTokens.width}) =>
      BorderSide(color: color, width: width);

  static Border all(Color color, {double width = BorderTokens.width}) =>
      Border.all(color: color, width: width);
}
