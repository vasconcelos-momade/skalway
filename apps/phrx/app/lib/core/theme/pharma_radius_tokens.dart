import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'radius.dart';

/// Radius tokens (xs..full) como ThemeExtension especializada.
@immutable
class PharmaRadiusTokens extends ThemeExtension<PharmaRadiusTokens> {
  const PharmaRadiusTokens({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.x2l,
    required this.x3l,
    required this.full,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double x2l;
  final double x3l;
  final double full;

  factory PharmaRadiusTokens.fromLegacy(PharmaTokens tokens) {
    return PharmaRadiusTokens(
      xs: RadiusScale.xs,
      sm: RadiusScale.sm,
      md: tokens.radiusMd,
      lg: RadiusScale.lg,
      xl: tokens.radiusXl,
      x2l: tokens.radius2xl,
      x3l: tokens.radius3xl,
      full: RadiusScale.full,
    );
  }

  @override
  PharmaRadiusTokens copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? x2l,
    double? x3l,
    double? full,
  }) {
    return PharmaRadiusTokens(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      x2l: x2l ?? this.x2l,
      x3l: x3l ?? this.x3l,
      full: full ?? this.full,
    );
  }

  @override
  PharmaRadiusTokens lerp(ThemeExtension<PharmaRadiusTokens>? other, double t) {
    if (other is! PharmaRadiusTokens) return this;
    return PharmaRadiusTokens(
      xs: lerpDouble(xs, other.xs, t)!,
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
      x2l: lerpDouble(x2l, other.x2l, t)!,
      x3l: lerpDouble(x3l, other.x3l, t)!,
      full: lerpDouble(full, other.full, t)!,
    );
  }
}

extension PharmaRadiusTokensX on BuildContext {
  PharmaRadiusTokens get radius =>
      Theme.of(this).extension<PharmaRadiusTokens>() ??
      PharmaRadiusTokens.fromLegacy(pharmaTokens);
}

