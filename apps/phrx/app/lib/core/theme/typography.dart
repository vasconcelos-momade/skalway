import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'typography_tokens.dart';

/// **Inter** corpo / UI; **Poppins** títulos (estilo executivo).
///
/// Na **web** usa apenas o `TextTheme` do Material (sem [GoogleFonts] em runtime).
///
/// Escala oficial — ver [TypographyTokens].
abstract final class AppTypography {
  AppTypography._();

  static TextStyle _poppinsTitle({
    required double fontSize,
    required FontWeight fontWeight,
    double? letterSpacing,
    required double height,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle _interBody({
    required double fontSize,
    required FontWeight fontWeight,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle _webStyle(
    TextStyle? base, {
    required double fontSize,
    required FontWeight fontWeight,
    double? letterSpacing,
    double? height,
  }) {
    return _w(base).copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Monospace para códigos, números tabulares e IDs.
  static TextStyle monospace({
    required Brightness brightness,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    final theme = textThemeFor(brightness);
    final base = theme.bodySmall ?? const TextStyle();
    final fallback = base.copyWith(
      fontFamily: 'monospace',
      fontFeatures: const [FontFeature.tabularFigures()],
      fontSize: fontSize ?? base.fontSize,
      fontWeight: fontWeight ?? TypographyTokens.medium,
      height: 1.35,
    );
    if (kIsWeb) return fallback;
    return GoogleFonts.jetBrainsMono(textStyle: fallback);
  }

  /// Caption — alias de [TextTheme.bodySmall].
  static TextStyle caption(TextTheme theme) => theme.erpCaption;

  /// Overline — alias de [TextTheme.labelSmall] com tracking ERP.
  static TextStyle overline(TextTheme theme) => theme.erpOverline;

  /// AppBar discreta — apenas contexto da rota, não o registo.
  static TextStyle appBarTitle(TextTheme theme) => theme.erpAppBarTitle;

  /// Título de página no conteúdo — escala oficial do ERP.
  static TextStyle pageTitle(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return theme.erpPageTitle;
  }

  /// KPI: rótulo superior compacto.
  static TextStyle kpiLabel(TextTheme theme, {bool compact = true}) {
    return compact ? theme.erpOverline : theme.labelSmall ?? theme.erpCaption;
  }

  /// KPI: valor numérico.
  static TextStyle kpiValue(TextTheme theme, {bool compact = true}) {
    return compact
        ? (theme.titleLarge ?? theme.erpCardTitle)
        : (theme.erpDisplayLarge);
  }

  static TextTheme textThemeFor(Brightness brightness) {
    final base = ThemeData(useMaterial3: true, brightness: brightness).textTheme;
    if (kIsWeb) {
      return _webEnterpriseTextTheme(base);
    }
    final inter = GoogleFonts.interTextTheme(base);
    final display = _poppinsTitle(
      fontSize: TypographyTokens.display,
      fontWeight: TypographyTokens.semibold,
      letterSpacing: -0.2,
      height: TypographyTokens.displayHeight,
    );
    final pageTitle = _poppinsTitle(
      fontSize: TypographyTokens.heading,
      fontWeight: TypographyTokens.semibold,
      height: TypographyTokens.headingHeight,
    );
    final sectionTitle = _poppinsTitle(
      fontSize: TypographyTokens.title,
      fontWeight: TypographyTokens.semibold,
      height: TypographyTokens.titleHeight,
    );
    final emphasisBody = _interBody(
      fontSize: TypographyTokens.title,
      fontWeight: TypographyTokens.semibold,
      height: TypographyTokens.titleHeight,
    );
    final tabLabel = _interBody(
      fontSize: TypographyTokens.subtitle,
      fontWeight: TypographyTokens.medium,
      height: TypographyTokens.titleHeight,
    );
    final body = _interBody(
      fontSize: TypographyTokens.body,
      fontWeight: TypographyTokens.regular,
      height: TypographyTokens.bodyHeight,
    );
    final bodySecondary = _interBody(
      fontSize: TypographyTokens.bodySmall,
      fontWeight: TypographyTokens.regular,
      height: TypographyTokens.bodyHeight,
    );
    final caption = _interBody(
      fontSize: TypographyTokens.caption,
      fontWeight: TypographyTokens.regular,
      height: TypographyTokens.captionHeight,
    );
    final label = _interBody(
      fontSize: TypographyTokens.label,
      fontWeight: TypographyTokens.medium,
      letterSpacing: 0,
    );
    final microLabel = _interBody(
      fontSize: TypographyTokens.caption,
      fontWeight: TypographyTokens.regular,
      letterSpacing: 0,
      height: 1.3,
    );
    return GoogleFonts.poppinsTextTheme(inter).copyWith(
      displayLarge: display,
      displayMedium: display,
      displaySmall: display,
      headlineLarge: pageTitle,
      headlineMedium: sectionTitle,
      headlineSmall: sectionTitle,
      titleLarge: sectionTitle,
      titleMedium: emphasisBody,
      titleSmall: tabLabel,
      bodyLarge: body,
      bodyMedium: bodySecondary,
      bodySmall: caption,
      labelLarge: label,
      labelMedium: label,
      labelSmall: microLabel,
    );
  }

  static TextStyle _w(TextStyle? s) => s ?? const TextStyle();

  static TextTheme _webEnterpriseTextTheme(TextTheme base) {
    final display = _webStyle(
      base.displayLarge,
      fontSize: TypographyTokens.display,
      fontWeight: TypographyTokens.semibold,
      letterSpacing: -0.2,
      height: TypographyTokens.displayHeight,
    );
    final pageTitle = _webStyle(
      base.headlineLarge,
      fontSize: TypographyTokens.heading,
      fontWeight: TypographyTokens.semibold,
      height: TypographyTokens.headingHeight,
    );
    final sectionTitle = _webStyle(
      base.headlineMedium,
      fontSize: TypographyTokens.title,
      fontWeight: TypographyTokens.semibold,
      height: TypographyTokens.titleHeight,
    );
    final emphasisBody = _webStyle(
      base.titleMedium,
      fontSize: TypographyTokens.title,
      fontWeight: TypographyTokens.semibold,
      height: TypographyTokens.titleHeight,
    );
    final tabLabel = _webStyle(
      base.titleSmall,
      fontSize: TypographyTokens.subtitle,
      fontWeight: TypographyTokens.medium,
      height: TypographyTokens.titleHeight,
    );
    final body = _webStyle(
      base.bodyLarge,
      fontSize: TypographyTokens.body,
      fontWeight: TypographyTokens.regular,
      height: TypographyTokens.bodyHeight,
    );
    final bodySecondary = _webStyle(
      base.bodyMedium,
      fontSize: TypographyTokens.bodySmall,
      fontWeight: TypographyTokens.regular,
      height: TypographyTokens.bodyHeight,
    );
    final caption = _webStyle(
      base.bodySmall,
      fontSize: TypographyTokens.caption,
      fontWeight: TypographyTokens.regular,
      height: TypographyTokens.captionHeight,
    );
    final label = _webStyle(
      base.labelLarge,
      fontSize: TypographyTokens.label,
      fontWeight: TypographyTokens.medium,
      letterSpacing: 0,
    );
    final microLabel = _webStyle(
      base.labelSmall,
      fontSize: TypographyTokens.caption,
      fontWeight: TypographyTokens.regular,
      letterSpacing: 0,
      height: 1.3,
    );
    return base.copyWith(
      displayLarge: display,
      displayMedium: display,
      displaySmall: display,
      headlineLarge: pageTitle,
      headlineMedium: sectionTitle,
      headlineSmall: sectionTitle,
      titleLarge: sectionTitle,
      titleMedium: emphasisBody,
      titleSmall: tabLabel,
      bodyLarge: body,
      bodyMedium: bodySecondary,
      bodySmall: caption,
      labelLarge: label,
      labelMedium: label,
      labelSmall: microLabel,
    );
  }

  /// Legado — preferir [textThemeFor].
  static TextTheme get textTheme => textThemeFor(Brightness.dark);
}

/// Papéis tipográficos ERP sobre [TextTheme] Material 3.
extension EnterpriseTextTheme on TextTheme {
  TextStyle get erpDisplayLarge => displayLarge ?? const TextStyle();
  TextStyle get erpDisplayMedium => displayMedium ?? const TextStyle();
  TextStyle get erpPageTitle => headlineLarge ?? const TextStyle();
  TextStyle get erpSectionTitle => headlineMedium ?? const TextStyle();
  TextStyle get erpCardTitle => titleLarge ?? const TextStyle();
  TextStyle get erpAppName => erpAppBarTitle;
  TextStyle get erpAppBarTitle => (titleLarge ?? const TextStyle()).copyWith(
        fontSize: TypographyTokens.appBar,
        fontWeight: TypographyTokens.semibold,
        letterSpacing: 0,
        height: TypographyTokens.titleHeight,
      );

  /// AppBar mantém a escala oficial em todos os breakpoints.
  TextStyle erpAppBarTitleFor(BuildContext context) {
    return erpAppBarTitle;
  }
  TextStyle get erpTabLabel => titleSmall ?? const TextStyle();
  TextStyle get erpLabel => labelLarge ?? const TextStyle();
  TextStyle get erpButtonPrimary =>
      erpLabel.copyWith(fontWeight: TypographyTokens.semibold);
  TextStyle get erpButtonSecondary =>
      erpLabel.copyWith(fontWeight: TypographyTokens.medium);
  TextStyle get erpFieldLabel => erpBodySecondary.copyWith(
        fontWeight: TypographyTokens.semibold,
        fontSize: TypographyTokens.fieldLabel,
        height: TypographyTokens.captionHeight,
        color: null, // cor via tokens.textPrimary no consumidor
      );
  TextStyle get erpSelectLabel => erpFieldLabel;
  TextStyle get erpSelectValue =>
      erpBody.copyWith(fontWeight: TypographyTokens.medium);
  TextStyle get erpMenuItem => erpTabLabel.copyWith(
        fontSize: TypographyTokens.subtitle,
        fontWeight: TypographyTokens.medium,
        height: 1.2,
      );
  TextStyle get erpMenuItemActive => erpMenuItem.copyWith(
        fontWeight: TypographyTokens.semibold,
      );
  TextStyle get erpBody => bodyLarge ?? const TextStyle();
  TextStyle get erpBodyMedium =>
      erpBody.copyWith(fontWeight: TypographyTokens.medium);
  TextStyle get erpBodyStrong =>
      erpBody.copyWith(fontWeight: TypographyTokens.semibold);
  TextStyle get erpBodySecondary => bodyMedium ?? const TextStyle();
  TextStyle get erpCaption => bodySmall ?? const TextStyle();
  TextStyle get erpOverline => (labelSmall ?? const TextStyle()).copyWith(
        fontWeight: TypographyTokens.medium,
        letterSpacing: 0.4,
        height: 1.2,
      );

  /// Tipografia de tabelas — alinhada à sidebar ([erpTabLabel]).
  TextStyle get erpTableHeader => erpTabLabel.copyWith(
        fontSize: TypographyTokens.tableHeader,
        fontWeight: TypographyTokens.semibold,
        letterSpacing: 0.2,
        height: TypographyTokens.tableHeight,
      );

  TextStyle get erpTablePrimary => erpTabLabel.copyWith(
        fontSize: TypographyTokens.tableCell,
        fontWeight: TypographyTokens.semibold,
        height: TypographyTokens.tableHeight,
      );

  TextStyle get erpTableSecondary => erpTabLabel.copyWith(
        fontSize: TypographyTokens.tableCell,
        fontWeight: TypographyTokens.medium,
        height: TypographyTokens.tableHeight,
      );

  /// Códigos, emails, referências e textos auxiliares.
  TextStyle get erpTableMetadata => erpBodySecondary.copyWith(height: 1.3);

  /// Legado — preferir [erpTableMetadata].
  TextStyle get erpTableMeta => erpTableMetadata;

  /// Valores numéricos e financeiros (alinhamento tabular).
  TextStyle get erpTableNumeric => erpTablePrimary.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Estados e badges de situação.
  TextStyle get erpTableStatus => erpBodySecondary.copyWith(height: 1.25);
}
