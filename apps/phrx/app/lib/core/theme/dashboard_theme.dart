import 'package:flutter/material.dart';

import 'design_tokens.dart';

@immutable
class DashboardTheme extends ThemeExtension<DashboardTheme> {
  const DashboardTheme({
    required this.cardPadding,
    required this.kpiSpacing,
    required this.chartHeight,
    required this.chartMinHeight,
    required this.chartMaxHeight,
    required this.chartAspectRatio,
    required this.pieChartAspectRatio,
    required this.chartGridStrokeWidth,
    required this.chartGridAlpha,
    required this.chartAreaFillAlpha,
    required this.pieEmptySectionAlpha,
    required this.chartPrimaryLineWidth,
    required this.chartSecondaryLineWidth,
    required this.chartBarWidth,
    required this.chartIndexedBarWidth,
    required this.chartBarRadius,
    required this.chartAxisReservedSizeLine,
    required this.chartAxisReservedSizeBar,
    required this.chartAxisLabelSpace,
    required this.chartBarLabelAngle,
    required this.chartIndexedBarLabelAngle,
    required this.chartTitleSpacing,
    required this.pieSectionSpace,
    required this.pieCenterSpaceRadius,
    required this.pieSectionRadius,
    required this.trendUpColor,
    required this.trendDownColor,
    required this.badgeRadius,
  });

  final EdgeInsets cardPadding;
  final double kpiSpacing;
  final double chartHeight;
  final double chartMinHeight;
  final double chartMaxHeight;
  final double chartAspectRatio;
  final double pieChartAspectRatio;
  final double chartGridStrokeWidth;
  final double chartGridAlpha;
  final double chartAreaFillAlpha;
  final double pieEmptySectionAlpha;
  final double chartPrimaryLineWidth;
  final double chartSecondaryLineWidth;
  final double chartBarWidth;
  final double chartIndexedBarWidth;
  final double chartBarRadius;
  final double chartAxisReservedSizeLine;
  final double chartAxisReservedSizeBar;
  final double chartAxisLabelSpace;
  final double chartBarLabelAngle;
  final double chartIndexedBarLabelAngle;
  final double chartTitleSpacing;
  final double pieSectionSpace;
  final double pieCenterSpaceRadius;
  final double pieSectionRadius;
  final Color trendUpColor;
  final Color trendDownColor;
  final double badgeRadius;

  factory DashboardTheme.fromLegacy(PharmaTokens tokens) {
    final chartHeight = tokens.density.xxxl * 9 + tokens.density.xl;
    return DashboardTheme(
      cardPadding: tokens.density.cardPadding,
      kpiSpacing: tokens.density.md,
      chartHeight: chartHeight,
      chartMinHeight: chartHeight - tokens.density.xxxl,
      chartMaxHeight: chartHeight + tokens.density.xl,
      chartAspectRatio: 16 / 9,
      pieChartAspectRatio: 4 / 3,
      chartGridStrokeWidth: 1,
      chartGridAlpha: 0.22,
      chartAreaFillAlpha: 0.10,
      pieEmptySectionAlpha: 0.35,
      chartPrimaryLineWidth: 2.5,
      chartSecondaryLineWidth: 2,
      chartBarWidth: tokens.density.lg + tokens.density.xxs,
      chartIndexedBarWidth: tokens.density.lg + tokens.density.xs,
      chartBarRadius: tokens.radiusMd / 3,
      chartAxisReservedSizeLine: tokens.density.lg + tokens.density.xxs,
      chartAxisReservedSizeBar: tokens.density.lg + tokens.density.xs,
      chartAxisLabelSpace: tokens.density.xxs,
      chartBarLabelAngle: -0.35,
      chartIndexedBarLabelAngle: -0.3,
      chartTitleSpacing: tokens.density.sm,
      pieSectionSpace: tokens.density.xxs,
      pieCenterSpaceRadius: tokens.radiusMd + tokens.density.sm,
      pieSectionRadius: tokens.minTouchTarget,
      trendUpColor: tokens.brandGreen,
      trendDownColor: tokens.posDanger,
      badgeRadius: tokens.radiusMd,
    );
  }

  @override
  DashboardTheme copyWith({
    EdgeInsets? cardPadding,
    double? kpiSpacing,
    double? chartHeight,
    double? chartMinHeight,
    double? chartMaxHeight,
    double? chartAspectRatio,
    double? pieChartAspectRatio,
    double? chartGridStrokeWidth,
    double? chartGridAlpha,
    double? chartAreaFillAlpha,
    double? pieEmptySectionAlpha,
    double? chartPrimaryLineWidth,
    double? chartSecondaryLineWidth,
    double? chartBarWidth,
    double? chartIndexedBarWidth,
    double? chartBarRadius,
    double? chartAxisReservedSizeLine,
    double? chartAxisReservedSizeBar,
    double? chartAxisLabelSpace,
    double? chartBarLabelAngle,
    double? chartIndexedBarLabelAngle,
    double? chartTitleSpacing,
    double? pieSectionSpace,
    double? pieCenterSpaceRadius,
    double? pieSectionRadius,
    Color? trendUpColor,
    Color? trendDownColor,
    double? badgeRadius,
  }) {
    return DashboardTheme(
      cardPadding: cardPadding ?? this.cardPadding,
      kpiSpacing: kpiSpacing ?? this.kpiSpacing,
      chartHeight: chartHeight ?? this.chartHeight,
      chartMinHeight: chartMinHeight ?? this.chartMinHeight,
      chartMaxHeight: chartMaxHeight ?? this.chartMaxHeight,
      chartAspectRatio: chartAspectRatio ?? this.chartAspectRatio,
      pieChartAspectRatio: pieChartAspectRatio ?? this.pieChartAspectRatio,
      chartGridStrokeWidth: chartGridStrokeWidth ?? this.chartGridStrokeWidth,
      chartGridAlpha: chartGridAlpha ?? this.chartGridAlpha,
      chartAreaFillAlpha: chartAreaFillAlpha ?? this.chartAreaFillAlpha,
      pieEmptySectionAlpha: pieEmptySectionAlpha ?? this.pieEmptySectionAlpha,
      chartPrimaryLineWidth: chartPrimaryLineWidth ?? this.chartPrimaryLineWidth,
      chartSecondaryLineWidth: chartSecondaryLineWidth ?? this.chartSecondaryLineWidth,
      chartBarWidth: chartBarWidth ?? this.chartBarWidth,
      chartIndexedBarWidth: chartIndexedBarWidth ?? this.chartIndexedBarWidth,
      chartBarRadius: chartBarRadius ?? this.chartBarRadius,
      chartAxisReservedSizeLine: chartAxisReservedSizeLine ?? this.chartAxisReservedSizeLine,
      chartAxisReservedSizeBar: chartAxisReservedSizeBar ?? this.chartAxisReservedSizeBar,
      chartAxisLabelSpace: chartAxisLabelSpace ?? this.chartAxisLabelSpace,
      chartBarLabelAngle: chartBarLabelAngle ?? this.chartBarLabelAngle,
      chartIndexedBarLabelAngle: chartIndexedBarLabelAngle ?? this.chartIndexedBarLabelAngle,
      chartTitleSpacing: chartTitleSpacing ?? this.chartTitleSpacing,
      pieSectionSpace: pieSectionSpace ?? this.pieSectionSpace,
      pieCenterSpaceRadius: pieCenterSpaceRadius ?? this.pieCenterSpaceRadius,
      pieSectionRadius: pieSectionRadius ?? this.pieSectionRadius,
      trendUpColor: trendUpColor ?? this.trendUpColor,
      trendDownColor: trendDownColor ?? this.trendDownColor,
      badgeRadius: badgeRadius ?? this.badgeRadius,
    );
  }

  @override
  DashboardTheme lerp(ThemeExtension<DashboardTheme>? other, double t) {
    if (other is! DashboardTheme) return this;
    return t < 0.5 ? this : other;
  }

  static double? lerpDouble(num? a, num? b, double t) {
    if (a == null && b == null) return null;
    a ??= 0.0;
    b ??= 0.0;
    return a + (b - a) * t;
  }
}

extension DashboardThemeX on BuildContext {
  DashboardTheme get dashboardTheme =>
      Theme.of(this).extension<DashboardTheme>() ??
      DashboardTheme.fromLegacy(
        Theme.of(this).extension<PharmaTokens>() ?? PharmaTokens.enterpriseLight(),
      );
}
