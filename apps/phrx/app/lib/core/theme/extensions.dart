import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'pharma_color_tokens.dart';
import 'elevation.dart';
import 'shadows.dart';
import 'motion.dart';
import 'typography.dart';
import 'breakpoints.dart';
import 'pharma_radius_tokens.dart';
import 'width_tokens.dart';
import 'elevation_tokens.dart';

export 'typography.dart' show EnterpriseTextTheme, AppTypography;
export 'spacing.dart';
export 'spacing_tokens.dart';
export 'radius.dart';
export 'elevation.dart';
export 'elevation_tokens.dart';
export 'width_tokens.dart';
export 'shadows.dart';
export 'motion.dart';
export 'breakpoints.dart';

class MotionAccess {
  const MotionAccess();
  Duration get durationFastest => Motion.durationFastest;
  Duration get durationFaster => Motion.durationFaster;
  Duration get durationFast => Motion.durationFast;
  Duration get durationNormal => Motion.durationNormal;
  Duration get durationSlow => Motion.durationSlow;
  Duration get durationSlower => Motion.durationSlower;
  Curve get ease => Motion.ease;
  Curve get easeIn => Motion.easeIn;
  Curve get easeOut => Motion.easeOut;
  Curve get easeInOut => Motion.easeInOut;
  Curve get emphasized => Motion.emphasized;
}

class ShadowsAccess {
  const ShadowsAccess();
  List<BoxShadow> get xs => ShadowScale.xs;
  List<BoxShadow> get sm => ShadowScale.sm;
  List<BoxShadow> get md => ShadowScale.md;
  List<BoxShadow> get lg => ShadowScale.lg;
  List<BoxShadow> get xl => ShadowScale.xl;
}

class ElevationAccess {
  const ElevationAccess();
  double get e0 => Elevation.e0;
  double get e1 => Elevation.e1;
  double get e2 => Elevation.e2;
  double get e3 => Elevation.e3;
  double get e4 => Elevation.e4;
  double get e6 => Elevation.e6;
  double get e8 => Elevation.e8;
  double get e12 => Elevation.e12;
  double get e16 => Elevation.e16;
  double get e24 => Elevation.e24;
}

extension ThemeContextExtension on BuildContext {
  /// Tokens originais (retrocompatibilidade)
  PharmaTokens get tokens =>
      Theme.of(this).extension<PharmaTokens>() ?? PharmaTokens.enterpriseLight();

  /// Cores MD3 + Enterprise
  PharmaColorTokens get colors =>
      Theme.of(this).extension<PharmaColorTokens>() ??
      PharmaColorTokens.fromLegacy(
        tokens: tokens,
        scheme: Theme.of(this).colorScheme,
      );

  /// Typography (TextTheme + papéis ERP)
  TextTheme get typography => Theme.of(this).textTheme;

  /// Título de página no conteúdo (responsivo).
  TextStyle get erpPageTitle => AppTypography.pageTitle(this);

  /// Radius
  PharmaRadiusTokens get radius =>
      Theme.of(this).extension<PharmaRadiusTokens>() ??
      PharmaRadiusTokens.fromLegacy(tokens);

  /// Motion
  MotionAccess get motion => const MotionAccess();

  /// Shadows
  ShadowsAccess get shadows => const ShadowsAccess();

  /// Elevation (escala numérica)
  ElevationAccess get elevation => const ElevationAccess();

  /// Elevation como ThemeExtension
  ElevationTokens get elevationTokens =>
      Theme.of(this).extension<ElevationTokens>() ?? ElevationTokens.standard();

  /// Larguras máximas por contexto
  WidthTokens get widths =>
      Theme.of(this).extension<WidthTokens>() ?? WidthTokens.standard();

  /// Utilitários de Breakpoints
  bool get isMobile => Breakpoints.isMobile(this);
  bool get isTablet => Breakpoints.isTablet(this);
  bool get isDesktop => Breakpoints.isDesktop(this);
  bool get isDesktopLarge => Breakpoints.isDesktopLarge(this);

  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? desktopLarge,
  }) {
    return Breakpoints.responsiveValue(
      this,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      desktopLarge: desktopLarge,
    );
  }
}
