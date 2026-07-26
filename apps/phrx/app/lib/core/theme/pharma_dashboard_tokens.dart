import 'package:flutter/material.dart';

import 'design_tokens.dart';

@immutable
class PharmaDashboardTokens extends ThemeExtension<PharmaDashboardTokens> {
  const PharmaDashboardTokens({
    required this.dashboardBackground,
    required this.dashboardCard,
    required this.widgetBackground,
    required this.widgetBorder,
    required this.widgetShadow,
  });

  final Color dashboardBackground;
  final Color dashboardCard;
  final Color widgetBackground;
  final Color widgetBorder;
  final List<BoxShadow> widgetShadow;

  factory PharmaDashboardTokens.fromLegacy(PharmaTokens tokens) {
    return PharmaDashboardTokens(
      dashboardBackground: tokens.bgPrimary,
      dashboardCard: tokens.card,
      widgetBackground: tokens.card,
      widgetBorder: tokens.border,
      widgetShadow: const [],
    );
  }

  @override
  PharmaDashboardTokens copyWith({
    Color? dashboardBackground,
    Color? dashboardCard,
    Color? widgetBackground,
    Color? widgetBorder,
    List<BoxShadow>? widgetShadow,
  }) {
    return PharmaDashboardTokens(
      dashboardBackground: dashboardBackground ?? this.dashboardBackground,
      dashboardCard: dashboardCard ?? this.dashboardCard,
      widgetBackground: widgetBackground ?? this.widgetBackground,
      widgetBorder: widgetBorder ?? this.widgetBorder,
      widgetShadow: widgetShadow ?? this.widgetShadow,
    );
  }

  @override
  PharmaDashboardTokens lerp(
    ThemeExtension<PharmaDashboardTokens>? other,
    double t,
  ) {
    if (other is! PharmaDashboardTokens) return this;
    return t < 0.5 ? this : other;
  }
}

extension PharmaDashboardTokensX on BuildContext {
  PharmaDashboardTokens get dashboardTokens =>
      Theme.of(this).extension<PharmaDashboardTokens>() ??
      PharmaDashboardTokens.fromLegacy(pharmaTokens);
}

