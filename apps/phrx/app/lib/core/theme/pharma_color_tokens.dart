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
    required this.primarySubtle,
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
    required this.successSubtle,
    required this.warningSubtle,
    required this.errorSubtle,
    required this.infoSubtle,
    required this.neutralSubtle,
    required this.fieldHover,
    required this.fieldDisabled,
    required this.sidebarActiveBackground,
    required this.sidebarActiveIndicator,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color primarySubtle;

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
  final Color successSubtle;
  final Color warningSubtle;
  final Color errorSubtle;
  final Color infoSubtle;
  final Color neutralSubtle;
  final Color fieldHover;
  final Color fieldDisabled;
  final Color sidebarActiveBackground;
  final Color sidebarActiveIndicator;

  factory PharmaColorTokens.fromLegacy({
    required PharmaTokens tokens,
    required ColorScheme scheme,
  }) {
    final isDark = scheme.brightness == Brightness.dark;
    final primarySubtle = Color.alphaBlend(
      scheme.primary.withValues(alpha: isDark ? 0.14 : 0.06),
      tokens.surface1,
    );

    return PharmaColorTokens(
      primary: scheme.primary,
      secondary: scheme.secondary,
      tertiary: scheme.tertiary,
      primarySubtle: primarySubtle,
      // Hierarquia de superfícies 0–4 via tokens.
      surface: tokens.surface1,
      surfaceVariant: tokens.surface2,
      surfaceContainerLow: tokens.surface1,
      surfaceContainer: tokens.surface2,
      surfaceContainerHigh: tokens.surface3,
      surfaceContainerHighest: tokens.surface3,
      background: tokens.surface0,
      backgroundSecondary: tokens.surface1,
      overlay: tokens.surface4,
      divider: tokens.borderSubtle,
      hover: tokens.surface2,
      pressed: tokens.surface3,
      focused: scheme.primary.withValues(alpha: isDark ? 0.28 : 0.18),
      // Selecção neutra — primária reservada a CTAs e indicador de nav.
      selected: Color.alphaBlend(
        tokens.textPrimary.withValues(alpha: isDark ? 0.08 : 0.05),
        tokens.surface2,
      ),
      disabled: tokens.textDisabled.withValues(alpha: 0.38),
      inverseSurface: scheme.inverseSurface,
      inversePrimary: scheme.inversePrimary,
      success: tokens.posSuccess,
      warning: tokens.posWarning,
      error: tokens.posDanger,
      info: tokens.posInfo,
      neutral: tokens.textMuted,
      successSubtle: Color.alphaBlend(
        tokens.posSuccess.withValues(alpha: isDark ? 0.18 : 0.10),
        tokens.surface2,
      ),
      warningSubtle: Color.alphaBlend(
        tokens.posWarning.withValues(alpha: isDark ? 0.18 : 0.10),
        tokens.surface2,
      ),
      errorSubtle: Color.alphaBlend(
        tokens.posDanger.withValues(alpha: isDark ? 0.18 : 0.10),
        tokens.surface2,
      ),
      infoSubtle: Color.alphaBlend(
        tokens.posInfo.withValues(alpha: isDark ? 0.18 : 0.10),
        tokens.surface2,
      ),
      neutralSubtle: isDark ? tokens.surface3 : tokens.surface1,
      fieldHover: isDark ? tokens.surface4 : tokens.surface1,
      fieldDisabled: isDark ? tokens.surface2 : tokens.surface1,
      // Fundo suave neutro; a cor primária fica na barra de 3px.
      sidebarActiveBackground: isDark ? tokens.surface3 : tokens.surface1,
      sidebarActiveIndicator: scheme.primary,
    );
  }

  @override
  PharmaColorTokens copyWith({
    Color? primary,
    Color? secondary,
    Color? tertiary,
    Color? primarySubtle,
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
    Color? successSubtle,
    Color? warningSubtle,
    Color? errorSubtle,
    Color? infoSubtle,
    Color? neutralSubtle,
    Color? fieldHover,
    Color? fieldDisabled,
    Color? sidebarActiveBackground,
    Color? sidebarActiveIndicator,
  }) {
    return PharmaColorTokens(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      primarySubtle: primarySubtle ?? this.primarySubtle,
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
      successSubtle: successSubtle ?? this.successSubtle,
      warningSubtle: warningSubtle ?? this.warningSubtle,
      errorSubtle: errorSubtle ?? this.errorSubtle,
      infoSubtle: infoSubtle ?? this.infoSubtle,
      neutralSubtle: neutralSubtle ?? this.neutralSubtle,
      fieldHover: fieldHover ?? this.fieldHover,
      fieldDisabled: fieldDisabled ?? this.fieldDisabled,
      sidebarActiveBackground:
          sidebarActiveBackground ?? this.sidebarActiveBackground,
      sidebarActiveIndicator:
          sidebarActiveIndicator ?? this.sidebarActiveIndicator,
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
