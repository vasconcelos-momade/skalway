import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// ThemeExtension especializada apenas para cores (padrão enterprise).
///
/// Mantém retrocompatibilidade: não substitui [PharmaTokens], apenas complementa.
@immutable
class PharmaColorTokens extends ThemeExtension<PharmaColorTokens> {
  const PharmaColorTokens({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceContainer,
    required this.surfaceContainerLow,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.background,
    required this.backgroundSecondary,
    required this.overlay,
    required this.divider,
    required this.hover,
    required this.pressed,
    required this.focused,
    required this.selected,
    required this.disabled,
    required this.inverseSurface,
    required this.inversePrimary,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.neutral,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;

  final Color surface;
  final Color surfaceVariant;
  final Color surfaceContainer;
  final Color surfaceContainerLow;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;

  final Color background;
  final Color backgroundSecondary;

  final Color overlay;
  final Color divider;

  final Color hover;
  final Color pressed;
  final Color focused;
  final Color selected;
  final Color disabled;

  final Color inverseSurface;
  final Color inversePrimary;

  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color neutral;

  factory PharmaColorTokens.fromLegacy({
    required PharmaTokens tokens,
    required ColorScheme scheme,
  }) {
    final isDark = scheme.brightness == Brightness.dark;

    return PharmaColorTokens(
      primary: scheme.primary,
      secondary: scheme.secondary,
      tertiary: scheme.tertiary,
      surface: scheme.surface,
      surfaceVariant: scheme.surfaceContainerHighest,
      surfaceContainer: scheme.surfaceContainer,
      surfaceContainerLow: scheme.surfaceContainerLow,
      surfaceContainerHigh: scheme.surfaceContainerHigh,
      surfaceContainerHighest: scheme.surfaceContainerHighest,
      background: tokens.bgPrimary,
      backgroundSecondary: tokens.bgSecondary,
      overlay: tokens.card.withValues(alpha: isDark ? 0.65 : 0.92),
      divider: tokens.border.withValues(alpha: isDark ? 0.5 : 0.7),
      hover: scheme.onSurface.withValues(alpha: isDark ? 0.12 : 0.06),
      pressed: scheme.onSurface.withValues(alpha: isDark ? 0.18 : 0.10),
      focused: scheme.primary.withValues(alpha: isDark ? 0.45 : 0.25),
      selected: scheme.primary.withValues(alpha: isDark ? 0.25 : 0.14),
      disabled: scheme.onSurface.withValues(alpha: 0.12),
      inverseSurface: scheme.inverseSurface,
      inversePrimary: scheme.inversePrimary,
      success: tokens.posSuccess,
      warning: tokens.posWarning,
      error: tokens.posDanger,
      info: tokens.posInfo,
      neutral: tokens.textMuted,
    );
  }

  @override
  PharmaColorTokens copyWith({
    Color? primary,
    Color? secondary,
    Color? tertiary,
    Color? surface,
    Color? surfaceVariant,
    Color? surfaceContainer,
    Color? surfaceContainerLow,
    Color? surfaceContainerHigh,
    Color? surfaceContainerHighest,
    Color? background,
    Color? backgroundSecondary,
    Color? overlay,
    Color? divider,
    Color? hover,
    Color? pressed,
    Color? focused,
    Color? selected,
    Color? disabled,
    Color? inverseSurface,
    Color? inversePrimary,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? neutral,
  }) {
    return PharmaColorTokens(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      surfaceContainerHighest:
          surfaceContainerHighest ?? this.surfaceContainerHighest,
      background: background ?? this.background,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      overlay: overlay ?? this.overlay,
      divider: divider ?? this.divider,
      hover: hover ?? this.hover,
      pressed: pressed ?? this.pressed,
      focused: focused ?? this.focused,
      selected: selected ?? this.selected,
      disabled: disabled ?? this.disabled,
      inverseSurface: inverseSurface ?? this.inverseSurface,
      inversePrimary: inversePrimary ?? this.inversePrimary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      neutral: neutral ?? this.neutral,
    );
  }

  @override
  PharmaColorTokens lerp(ThemeExtension<PharmaColorTokens>? other, double t) {
    if (other is! PharmaColorTokens) return this;
    return t < 0.5 ? this : other;
  }
}

extension PharmaColorTokensX on BuildContext {
  PharmaColorTokens get colors =>
      Theme.of(this).extension<PharmaColorTokens>() ??
      PharmaColorTokens.fromLegacy(
        tokens: pharmaTokens,
        scheme: Theme.of(this).colorScheme,
      );
}
