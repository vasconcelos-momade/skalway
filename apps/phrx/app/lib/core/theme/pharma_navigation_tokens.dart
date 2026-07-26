import 'package:flutter/material.dart';

import 'design_tokens.dart';

@immutable
class PharmaNavigationTokens extends ThemeExtension<PharmaNavigationTokens> {
  const PharmaNavigationTokens({
    required this.sidebarBackground,
    required this.sidebarSelected,
    required this.sidebarHover,
    required this.sidebarBorder,
    required this.topbarBackground,
    required this.topbarBorder,
    required this.navigationRail,
    required this.drawerBackground,
    required this.drawerBorder,
  });

  final Color sidebarBackground;
  final Color sidebarSelected;
  final Color sidebarHover;
  final Color sidebarBorder;

  final Color topbarBackground;
  final Color topbarBorder;

  final Color navigationRail;

  final Color drawerBackground;
  final Color drawerBorder;

  factory PharmaNavigationTokens.fromLegacy({
    required PharmaTokens tokens,
    required ColorScheme scheme,
  }) {
    final isDark = scheme.brightness == Brightness.dark;

    return PharmaNavigationTokens(
      sidebarBackground: tokens.bgSecondary,
      sidebarBorder: tokens.border.withValues(alpha: isDark ? 0.6 : 0.85),
      sidebarSelected: scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14),
      sidebarHover: scheme.onSurface.withValues(alpha: isDark ? 0.10 : 0.06),
      topbarBackground: tokens.bgSecondary,
      topbarBorder: tokens.border.withValues(alpha: isDark ? 0.55 : 0.75),
      navigationRail: tokens.bgSecondary,
      drawerBackground: tokens.bgSecondary,
      drawerBorder: tokens.border.withValues(alpha: isDark ? 0.55 : 0.75),
    );
  }

  @override
  PharmaNavigationTokens copyWith({
    Color? sidebarBackground,
    Color? sidebarSelected,
    Color? sidebarHover,
    Color? sidebarBorder,
    Color? topbarBackground,
    Color? topbarBorder,
    Color? navigationRail,
    Color? drawerBackground,
    Color? drawerBorder,
  }) {
    return PharmaNavigationTokens(
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      sidebarSelected: sidebarSelected ?? this.sidebarSelected,
      sidebarHover: sidebarHover ?? this.sidebarHover,
      sidebarBorder: sidebarBorder ?? this.sidebarBorder,
      topbarBackground: topbarBackground ?? this.topbarBackground,
      topbarBorder: topbarBorder ?? this.topbarBorder,
      navigationRail: navigationRail ?? this.navigationRail,
      drawerBackground: drawerBackground ?? this.drawerBackground,
      drawerBorder: drawerBorder ?? this.drawerBorder,
    );
  }

  @override
  PharmaNavigationTokens lerp(
    ThemeExtension<PharmaNavigationTokens>? other,
    double t,
  ) {
    if (other is! PharmaNavigationTokens) return this;
    return t < 0.5 ? this : other;
  }
}

extension PharmaNavigationTokensX on BuildContext {
  PharmaNavigationTokens get navigationTokens =>
      Theme.of(this).extension<PharmaNavigationTokens>() ??
      PharmaNavigationTokens.fromLegacy(
        tokens: pharmaTokens,
        scheme: Theme.of(this).colorScheme,
      );
}
