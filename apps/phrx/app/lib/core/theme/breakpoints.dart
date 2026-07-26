import 'package:flutter/widgets.dart';

/// Breakpoints partilhados entre layout, tokens e [responsive_framework].
///
/// Alinhamento PhRx (prompt navegação):
/// - Mobile: 0–599
/// - Tablet: 600–1279 (drawer)
/// - Desktop: ≥1280 (sidebar fixo)
abstract final class Breakpoints {
  Breakpoints._();

  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1280;
  static const double desktopLarge = 1536;
  static const double ultraWide = 1920;
  static const double foldable = 700;
  static const double watch = 300;
  static const double tv = 2560;

  /// Limite superior mobile (inclusive) para [responsive_framework].
  static const double responsiveMobileEnd = mobile - 1;

  /// Limite superior tablet (inclusive) para [responsive_framework].
  static const double responsiveTabletEnd = desktop - 1;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobile && width < desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;

  static bool isDesktopLarge(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopLarge;

  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? desktopLarge,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= Breakpoints.desktopLarge && desktopLarge != null) {
      return desktopLarge;
    }
    if (width >= Breakpoints.desktop && desktop != null) return desktop;
    if (width >= Breakpoints.tablet && tablet != null) return tablet;
    return mobile;
  }
}
