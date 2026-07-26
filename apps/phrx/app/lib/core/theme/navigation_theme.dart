import 'package:flutter/material.dart';

import 'design_tokens.dart';

@immutable
class NavigationThemeData extends ThemeExtension<NavigationThemeData> {
  const NavigationThemeData({
    required this.sidebarBackground,
    required this.sidebarSelected,
    required this.sidebarHover,
    required this.topbarBackground,
    required this.drawerBackground,
  });

  final Color sidebarBackground;
  final Color sidebarSelected;
  final Color sidebarHover;
  final Color topbarBackground;
  final Color drawerBackground;

  factory NavigationThemeData.fromLegacy(PharmaTokens tokens) {
    return NavigationThemeData(
      sidebarBackground: tokens.bgSecondary,
      sidebarSelected: tokens.brandGreen.withValues(alpha: 0.12),
      sidebarHover: tokens.cardHover,
      topbarBackground: tokens.bgPrimary,
      drawerBackground: tokens.bgSecondary,
    );
  }

  @override
  NavigationThemeData copyWith({
    Color? sidebarBackground,
    Color? sidebarSelected,
    Color? sidebarHover,
    Color? topbarBackground,
    Color? drawerBackground,
  }) {
    return NavigationThemeData(
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      sidebarSelected: sidebarSelected ?? this.sidebarSelected,
      sidebarHover: sidebarHover ?? this.sidebarHover,
      topbarBackground: topbarBackground ?? this.topbarBackground,
      drawerBackground: drawerBackground ?? this.drawerBackground,
    );
  }

  @override
  NavigationThemeData lerp(ThemeExtension<NavigationThemeData>? other, double t) {
    if (other is! NavigationThemeData) return this;
    return t < 0.5 ? this : other;
  }
}

extension NavigationThemeDataX on BuildContext {
  NavigationThemeData get navigationTheme =>
      Theme.of(this).extension<NavigationThemeData>() ??
      NavigationThemeData.fromLegacy(
        Theme.of(this).extension<PharmaTokens>() ?? PharmaTokens.enterpriseLight(),
      );
}
