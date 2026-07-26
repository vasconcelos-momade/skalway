import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'elevation.dart';

/// Elevação MD3 como [ThemeExtension] para consumo via `context.elevationTokens`.
@immutable
class ElevationTokens extends ThemeExtension<ElevationTokens> {
  const ElevationTokens({
    required this.level0,
    required this.level1,
    required this.level2,
    required this.level3,
    required this.level4,
    required this.level6,
    required this.level8,
    required this.level12,
    required this.level16,
    required this.level24,
  });

  final double level0;
  final double level1;
  final double level2;
  final double level3;
  final double level4;
  final double level6;
  final double level8;
  final double level12;
  final double level16;
  final double level24;

  factory ElevationTokens.standard() {
    return const ElevationTokens(
      level0: Elevation.e0,
      level1: Elevation.e1,
      level2: Elevation.e2,
      level3: Elevation.e3,
      level4: Elevation.e4,
      level6: Elevation.e6,
      level8: Elevation.e8,
      level12: Elevation.e12,
      level16: Elevation.e16,
      level24: Elevation.e24,
    );
  }

  @override
  ElevationTokens copyWith({
    double? level0,
    double? level1,
    double? level2,
    double? level3,
    double? level4,
    double? level6,
    double? level8,
    double? level12,
    double? level16,
    double? level24,
  }) {
    return ElevationTokens(
      level0: level0 ?? this.level0,
      level1: level1 ?? this.level1,
      level2: level2 ?? this.level2,
      level3: level3 ?? this.level3,
      level4: level4 ?? this.level4,
      level6: level6 ?? this.level6,
      level8: level8 ?? this.level8,
      level12: level12 ?? this.level12,
      level16: level16 ?? this.level16,
      level24: level24 ?? this.level24,
    );
  }

  @override
  ElevationTokens lerp(ThemeExtension<ElevationTokens>? other, double t) {
    if (other is! ElevationTokens) return this;
    return ElevationTokens(
      level0: lerpDouble(level0, other.level0, t)!,
      level1: lerpDouble(level1, other.level1, t)!,
      level2: lerpDouble(level2, other.level2, t)!,
      level3: lerpDouble(level3, other.level3, t)!,
      level4: lerpDouble(level4, other.level4, t)!,
      level6: lerpDouble(level6, other.level6, t)!,
      level8: lerpDouble(level8, other.level8, t)!,
      level12: lerpDouble(level12, other.level12, t)!,
      level16: lerpDouble(level16, other.level16, t)!,
      level24: lerpDouble(level24, other.level24, t)!,
    );
  }
}
