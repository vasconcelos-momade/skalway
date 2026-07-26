import 'design_tokens.dart';

/// Raios semânticos derivados de [PharmaTokens] (sem valores soltos no UI).
abstract final class AppRadius {
  AppRadius._();

  static double dialog(PharmaTokens tokens) => tokens.radiusXl;

  static double card(PharmaTokens tokens) => tokens.radiusMd;

  static double surfaceLarge(PharmaTokens tokens) => tokens.radius2xl;
}
