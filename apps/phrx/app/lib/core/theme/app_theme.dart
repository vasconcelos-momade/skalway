import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'component_theme.dart';
import 'design_tokens.dart';
import 'pharma_border_tokens.dart';
import 'pharma_color_tokens.dart';
import 'pharma_finance_tokens.dart';
import 'pharma_healthcare_tokens.dart';
import 'pharma_navigation_tokens.dart';
import 'pharma_radius_tokens.dart';
import 'typography.dart';
import 'width_tokens.dart';
import 'elevation_tokens.dart';
import 'dashboard_theme.dart';
import 'table_theme.dart';
import 'healthcare_theme.dart';
import 'navigation_theme.dart';

abstract final class AppTheme {
  AppTheme._();

  static ThemeData _enterpriseTheme({
    required PharmaTokens tokens,
    required Brightness brightness,
    required ColorScheme scheme,
  }) {
    final isDark = brightness == Brightness.dark;
    final colorTokens = PharmaColorTokens.fromLegacy(
      tokens: tokens,
      scheme: scheme,
    );
    final radiusTokens = PharmaRadiusTokens.fromLegacy(tokens);
    final borderTokens = PharmaBorderTokens.fromLegacy(tokens);
    final widthTokens = WidthTokens.standard();
    final elevationTokens = ElevationTokens.standard();
    final navigationTokens = PharmaNavigationTokens.fromLegacy(
      tokens: tokens,
      scheme: scheme,
    );
    final financeTokens = PharmaFinanceTokens.fromLegacy(tokens);
    final healthcareTokens = PharmaHealthcareTokens.fromLegacy(tokens);

    final textTheme = AppTypography.textThemeFor(
      brightness,
    ).apply(bodyColor: tokens.textPrimary, displayColor: tokens.textPrimary);

    final dashboardTheme = DashboardTheme.fromLegacy(tokens);
    final tableTheme = TableTheme.fromLegacy(
      tokens,
      textTheme: textTheme,
      scheme: scheme,
      colors: colorTokens,
    );
    final specificHealthcareTheme = HealthcareTheme.fromLegacy(tokens);
    final specificNavigationTheme = NavigationThemeData.fromLegacy(tokens);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.bgPrimary,
      extensions: [
        tokens,
        colorTokens,
        radiusTokens,
        borderTokens,
        widthTokens,
        elevationTokens,
        navigationTokens,
        financeTokens,
        healthcareTokens,
        dashboardTheme,
        tableTheme,
        specificHealthcareTheme,
        specificNavigationTheme,
      ],
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.bgPrimary,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: tokens.controlHeight,
        titleTextStyle: AppTypography.appBarTitle(
          textTheme,
        ).copyWith(color: tokens.textPrimary),
        toolbarTextStyle: textTheme.erpTabLabel.copyWith(
          color: tokens.textSecondary,
        ),
        actionsIconTheme: IconThemeData(
          size: tokens.iconMd,
          color: tokens.textPrimary,
        ),
        iconTheme: IconThemeData(
          size: tokens.iconMd,
          color: tokens.textPrimary,
        ),
      ),
      chipTheme: PharmaComponentTheme.chip(
        tokens,
        scheme,
        isDark: isDark,
        colors: colorTokens,
        textTheme: textTheme,
      ),
      tooltipTheme: PharmaComponentTheme.tooltip(
        tokens,
        scheme,
        textTheme: textTheme,
      ),
      snackBarTheme: PharmaComponentTheme.snackBar(
        tokens,
        scheme,
        textTheme: textTheme,
      ),
      scrollbarTheme: PharmaComponentTheme.scrollbar(tokens),
      cardTheme: PharmaComponentTheme.card(tokens, isDark: isDark),
      dialogTheme: PharmaComponentTheme.dialog(tokens, isDark: isDark),
      bottomSheetTheme: PharmaComponentTheme.bottomSheet(
        tokens,
        isDark: isDark,
      ),
      popupMenuTheme: PharmaComponentTheme.popupMenu(
        tokens,
        textTheme: textTheme,
      ),
      menuTheme: PharmaComponentTheme.menu(tokens, textTheme: textTheme),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: textTheme.erpSelectValue.copyWith(color: tokens.textPrimary),
        inputDecorationTheme: PharmaComponentTheme.input(
          tokens,
          scheme,
          isDark: isDark,
          colors: colorTokens,
          textTheme: textTheme,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: PharmaComponentTheme.filled(
          tokens,
          scheme,
          colors: colorTokens,
          textTheme: textTheme,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: PharmaComponentTheme.outlined(
          tokens,
          scheme,
          colors: colorTokens,
          textTheme: textTheme,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: PharmaComponentTheme.text(
          tokens,
          scheme,
          colors: colorTokens,
          textTheme: textTheme,
        ),
      ),
      iconButtonTheme: PharmaComponentTheme.iconButton(
        tokens,
        scheme,
        colors: colorTokens,
      ),
      inputDecorationTheme: PharmaComponentTheme.input(
        tokens,
        scheme,
        isDark: isDark,
        colors: colorTokens,
        textTheme: textTheme,
      ),
      checkboxTheme: PharmaComponentTheme.checkbox(scheme),
      switchTheme: PharmaComponentTheme.switchTheme(scheme),
      radioTheme: PharmaComponentTheme.radio(scheme),
      sliderTheme: PharmaComponentTheme.slider(scheme, textTheme: textTheme),
      dividerTheme: PharmaComponentTheme.divider(tokens, isDark: isDark),
      dataTableTheme: PharmaComponentTheme.dataTable(
        tokens,
        colors: colorTokens,
        textTheme: textTheme,
      ),
      listTileTheme: PharmaComponentTheme.listTile(tokens),
      navigationRailTheme: PharmaComponentTheme.navigationRail(
        tokens,
        scheme,
        textTheme: textTheme,
      ),
      navigationDrawerTheme: PharmaComponentTheme.navigationDrawer(
        tokens,
        scheme,
        isDark: isDark,
        colors: colorTokens,
      ),
      navigationBarTheme: PharmaComponentTheme.navigationBar(
        tokens,
        scheme,
        isDark: isDark,
        colors: colorTokens,
        textTheme: textTheme,
      ),
      progressIndicatorTheme: PharmaComponentTheme.progressIndicator(scheme),
      tabBarTheme: PharmaComponentTheme.tabBar(
        tokens,
        scheme,
        isDark: isDark,
        textTheme: textTheme,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static const _enterpriseThemeRevision = 19;
  static final Map<(DensityLevel, int), ThemeData> _lightCache = {};
  static final Map<(DensityLevel, int), ThemeData> _darkCache = {};

  /// Invalida cache de temas (útil após alterações a tokens / TableTheme).
  static void clearEnterpriseThemeCache() {
    _lightCache.clear();
    _darkCache.clear();
  }

  static ThemeData lightEnterprise({
    DensityTokens density = DensityTokens.comfortable,
  }) {
    return _lightCache.putIfAbsent((density.level, _enterpriseThemeRevision), () {
      final tokens = PharmaTokens.enterpriseLight(density: density);
      final scheme = ColorScheme.light(
        surface: tokens.surface1,
        onSurface: tokens.textPrimary,
        primary: tokens.brandGreen,
        onPrimary: Colors.white,
        secondary: tokens.brandGreenHover,
        onSecondary: Colors.white,
        error: tokens.posDanger,
        onError: Colors.white,
        outline: tokens.border,
        outlineVariant: tokens.border,
        surfaceContainerLowest: tokens.surface0,
        surfaceContainerLow: tokens.surface1,
        surfaceContainer: tokens.surface2,
        surfaceContainerHigh: tokens.surface3,
        surfaceContainerHighest: tokens.surface3,
        surfaceTint: Colors.transparent,
      );

      return _enterpriseTheme(
        tokens: tokens,
        brightness: Brightness.light,
        scheme: scheme,
      );
    });
  }

  static ThemeData darkEnterprise({
    DensityTokens density = DensityTokens.comfortable,
  }) {
    return _darkCache.putIfAbsent((density.level, _enterpriseThemeRevision), () {
      final tokens = PharmaTokens.enterpriseDark(density: density);
      final scheme = ColorScheme.dark(
        surface: tokens.surface1,
        onSurface: tokens.textPrimary,
        primary: tokens.brandGreen,
        onPrimary: AppColors.ink950,
        secondary: tokens.brandGreenHover,
        onSecondary: AppColors.ink950,
        error: tokens.posDanger,
        onError: Colors.white,
        outline: tokens.border,
        outlineVariant: tokens.border,
        surfaceContainerLowest: tokens.surface0,
        surfaceContainerLow: tokens.surface1,
        surfaceContainer: tokens.surface2,
        surfaceContainerHigh: tokens.surface3,
        surfaceContainerHighest: tokens.surface3,
        surfaceTint: Colors.transparent,
      );

      return _enterpriseTheme(
        tokens: tokens,
        brightness: Brightness.dark,
        scheme: scheme,
      );
    });
  }

  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    textTheme: AppTypography.textThemeFor(Brightness.light),
    useMaterial3: true,
  );
}
