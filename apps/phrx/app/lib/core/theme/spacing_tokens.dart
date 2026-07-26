import 'package:flutter/widgets.dart';

/// Escala canónica de espaçamento MD3 / ERP.
///
/// Valores permitidos: **4, 8, 12, 16, 24, 32**.
abstract final class SpacingTokens {
  SpacingTokens._();

  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;

  /// Aliases semânticos (mapeiam à escala canónica).
  static const double xs = s4;
  static const double sm = s8;
  static const double md = s12;
  static const double lg = s16;
  static const double xl = s24;
  static const double xxl = s32;

  static const double gutter = s16;
  static const double page = s16;

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(gutter, md, gutter, lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  static EdgeInsets all(double value) => EdgeInsets.all(value);
  static EdgeInsets horizontal(double value) =>
      EdgeInsets.symmetric(horizontal: value);
  static EdgeInsets vertical(double value) =>
      EdgeInsets.symmetric(vertical: value);
  static EdgeInsets symmetric({double h = 0, double v = 0}) =>
      EdgeInsets.symmetric(horizontal: h, vertical: v);
  static EdgeInsets only({
    double l = 0,
    double t = 0,
    double r = 0,
    double b = 0,
  }) =>
      EdgeInsets.only(left: l, top: t, right: r, bottom: b);
}
