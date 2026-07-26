import 'package:flutter/widgets.dart';

/// Escala canónica de radius (alinhada à escala de spacing).
abstract final class RadiusScale {
  RadiusScale._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double full = 9999;

  static BorderRadius all(double value) =>
      BorderRadius.all(Radius.circular(value));
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

/// Alias semântico — preferir [PharmaRadiusTokens] via `context.radius`.
typedef RadiusTokens = RadiusScale;
