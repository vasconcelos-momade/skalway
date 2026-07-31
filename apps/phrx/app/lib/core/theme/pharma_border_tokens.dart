import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'border_tokens.dart';
import 'design_tokens.dart';

/// Border tokens (espessuras + foco/seleção) como ThemeExtension.
@immutable
class PharmaBorderTokens extends ThemeExtension<PharmaBorderTokens> {
  const PharmaBorderTokens({
    required this.borderThin,
    required this.borderMedium,
    required this.borderStrong,
    required this.focusBorder,
    required this.selectedBorder,
  });

  final double borderThin;
  final double borderMedium;
  final double borderStrong;
  final double focusBorder;
  final double selectedBorder;

  factory PharmaBorderTokens.fromLegacy(PharmaTokens tokens) {
    return const PharmaBorderTokens(
      borderThin: BorderTokens.width,
      borderMedium: BorderTokens.width,
      borderStrong: BorderTokens.width,
      focusBorder: BorderTokens.width,
      selectedBorder: BorderTokens.width,
    );
  }

  /// Cor de borda default (via tokens do tema).
  static Color colorDefault(PharmaTokens tokens) => tokens.border;

  /// Cor de borda subtle (via tokens do tema).
  static Color colorSubtle(PharmaTokens tokens) => tokens.borderSubtle;

  @override
  PharmaBorderTokens copyWith({
    double? borderThin,
    double? borderMedium,
    double? borderStrong,
    double? focusBorder,
    double? selectedBorder,
  }) {
    return PharmaBorderTokens(
      borderThin: borderThin ?? this.borderThin,
      borderMedium: borderMedium ?? this.borderMedium,
      borderStrong: borderStrong ?? this.borderStrong,
      focusBorder: focusBorder ?? this.focusBorder,
      selectedBorder: selectedBorder ?? this.selectedBorder,
    );
  }

  @override
  PharmaBorderTokens lerp(ThemeExtension<PharmaBorderTokens>? other, double t) {
    if (other is! PharmaBorderTokens) return this;
    return PharmaBorderTokens(
      borderThin: lerpDouble(borderThin, other.borderThin, t)!,
      borderMedium: lerpDouble(borderMedium, other.borderMedium, t)!,
      borderStrong: lerpDouble(borderStrong, other.borderStrong, t)!,
      focusBorder: lerpDouble(focusBorder, other.focusBorder, t)!,
      selectedBorder: lerpDouble(selectedBorder, other.selectedBorder, t)!,
    );
  }
}

extension PharmaBorderTokensX on BuildContext {
  PharmaBorderTokens get borders =>
      Theme.of(this).extension<PharmaBorderTokens>() ??
      PharmaBorderTokens.fromLegacy(pharmaTokens);
}

