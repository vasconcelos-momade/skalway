import 'package:flutter/widgets.dart';

import 'design_tokens.dart';
import 'spacing_tokens.dart';

export 'spacing_tokens.dart';

extension SpacingX on BuildContext {
  DensityTokens get spacing => pharmaTokens.density;
}

/// Utilitários de espaçamento — preferir [SpacingTokens] ou `context.spacing`.
abstract final class Spacing {
  Spacing._();

  static const double zero = 0;

  // Escala canónica (4, 8, 12, 16, 24, 32)
  static const double s4 = SpacingTokens.s4;
  static const double s8 = SpacingTokens.s8;
  static const double s12 = SpacingTokens.s12;
  static const double s16 = SpacingTokens.s16;
  static const double s24 = SpacingTokens.s24;
  static const double s32 = SpacingTokens.s32;

  @Deprecated('Use SpacingTokens.s4 ou Spacing.s4')
  static const double s2 = SpacingTokens.s4;

  @Deprecated('Use SpacingTokens.s24')
  static const double s20 = SpacingTokens.s24;

  @Deprecated('Use SpacingTokens.s24')
  static const double s28 = SpacingTokens.s24;

  @Deprecated('Use SpacingTokens.s32')
  static const double s40 = SpacingTokens.s32;

  @Deprecated('Use DesignMetrics.minTouchTarget (48)')
  static const double s48 = 48;

  @Deprecated('Use DesignMetrics.topBarCompact (56)')
  static const double s56 = 56;

  @Deprecated('Use DesignMetrics.topBarDesktop (72)')
  static const double s64 = 64;

  @Deprecated('Use DesignMetrics.topBarDesktop')
  static const double s72 = 72;

  @Deprecated('Use SpacingTokens.xxl')
  static const double s80 = SpacingTokens.s32;

  @Deprecated('Use SpacingTokens.xxl')
  static const double s96 = SpacingTokens.s32;

  @Deprecated('Use SpacingTokens.xxl')
  static const double s120 = SpacingTokens.s32;

  @Deprecated('Use SpacingTokens.xxl')
  static const double s160 = SpacingTokens.s32;

  static EdgeInsets all(double value) => SpacingTokens.all(value);
  static EdgeInsets horizontal(double value) => SpacingTokens.horizontal(value);
  static EdgeInsets vertical(double value) => SpacingTokens.vertical(value);
  static EdgeInsets symmetric({double h = 0, double v = 0}) =>
      SpacingTokens.symmetric(h: h, v: v);
  static EdgeInsets only({double l = 0, double t = 0, double r = 0, double b = 0}) =>
      SpacingTokens.only(l: l, t: t, r: r, b: b);
}

@Deprecated('Use SpacingTokens ou context.spacing')
abstract final class AppSpacing {
  AppSpacing._();

  static const double xxs = SpacingTokens.xs;
  static const double xs = SpacingTokens.xs;
  static const double sm = SpacingTokens.sm;
  static const double md = SpacingTokens.md;
  static const double lg = SpacingTokens.lg;

  @Deprecated('AppSpacing.xl mapeia para 24 (escala canónica)')
  static const double xl = SpacingTokens.xl;

  static const double xxl = SpacingTokens.xxl;
  static const double xxxl = SpacingTokens.xxl;
  static const double gutter = SpacingTokens.gutter;
  static const double page = SpacingTokens.page;

  static const EdgeInsets pagePadding = SpacingTokens.pagePadding;
  static const EdgeInsets cardPadding = SpacingTokens.cardPadding;
}
