import 'package:flutter/widgets.dart';

/// Escala canónica de border-radius.
///
/// Valores permitidos: **4, 8, 10, 9999**.
abstract final class RadiusTokens {
  RadiusTokens._();

  static const double sm = 4;
  static const double md = 8;
  static const double lg = 10;
  static const double full = 9999;

  /// Aliases de compatibilidade.
  static const double xs = sm;
  static const double xl = lg;
  static const double xxl = lg;
  static const double xxxl = lg;

  static BorderRadius all(double value) =>
      BorderRadius.all(Radius.circular(value));

  static BorderRadius circular(double value) =>
      BorderRadius.circular(value);

  static BorderRadius top(double value) =>
      BorderRadius.vertical(top: Radius.circular(value));

  static BorderRadius bottom(double value) =>
      BorderRadius.vertical(bottom: Radius.circular(value));

  static BorderRadius horizontal({double left = 0, double right = 0}) =>
      BorderRadius.horizontal(
        left: Radius.circular(left),
        right: Radius.circular(right),
      );
}
