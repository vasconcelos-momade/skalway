import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// **Inter** corpo / UI; **Poppins** títulos (estilo executivo).
///
/// Na **web** usa apenas o `TextTheme` do Material (sem [GoogleFonts] em runtime).
///
/// Escala oficial do Design System:
/// - Display: 28 / 600
/// - Titulo de pagina: 20 / 600
/// - Titulo de secao e card: 16 / 600
/// - AppBar: 18 / 600
/// - Tabs: 14 / 500
/// - Label: 14 / 500
/// - Texto principal: 14 / 400
/// - Texto secundario: 13 / 400
/// - Caption / metadata: 12 / 400
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
      fontWeight: fontWeight ?? FontWeight.w500,
      height: 1.35,
    );
    if (kIsWeb) return fallback;
    return GoogleFonts.jetBrainsMono(textStyle: fallback);
  }

  /// Caption — alias de [TextTheme.bodySmall].
  static TextStyle caption(TextTheme theme) => theme.erpCaption;

  /// Overline — alias de [TextTheme.labelSmall] com tracking ERP.
  static TextStyle overline(TextTheme theme) => theme.erpOverline;

  /// AppBar discreta (18px) — apenas contexto da rota, não o registo.
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
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.15,
    );
    final pageTitle = _poppinsTitle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.25,
    );
    final sectionTitle = _poppinsTitle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.25,
    );
    final emphasisBody = _interBody(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.25,
    );
    final tabLabel = _interBody(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.25,
    );
    final body = _interBody(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.4,
    );
    final bodySecondary = _interBody(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.4,
    );
    final caption = _interBody(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.4,
    );
    final label = _interBody(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );
    final microLabel = _interBody(
      fontSize: 12,
      fontWeight: FontWeight.w400,
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
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      height: 1.15,
    );
    final pageTitle = _webStyle(
      base.headlineLarge,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.25,
    );
    final sectionTitle = _webStyle(
      base.headlineMedium,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.25,
    );
    final emphasisBody = _webStyle(
      base.titleMedium,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.25,
    );
    final tabLabel = _webStyle(
      base.titleSmall,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.25,
    );
    final body = _webStyle(
      base.bodyLarge,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.4,
    );
    final bodySecondary = _webStyle(
      base.bodyMedium,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.4,
    );
    final caption = _webStyle(
      base.bodySmall,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.4,
    );
    final label = _webStyle(
      base.labelLarge,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );
    final microLabel = _webStyle(
      base.labelSmall,
      fontSize: 12,
      fontWeight: FontWeight.w400,
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
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.25,
      );

  /// AppBar mantém a escala oficial em todos os breakpoints.
  TextStyle erpAppBarTitleFor(BuildContext context) {
    return erpAppBarTitle;
  }
  TextStyle get erpTabLabel => titleSmall ?? const TextStyle();
  TextStyle get erpLabel => labelLarge ?? const TextStyle();
  TextStyle get erpButtonPrimary => erpLabel.copyWith(fontWeight: FontWeight.w600);
  TextStyle get erpButtonSecondary => erpLabel.copyWith(fontWeight: FontWeight.w500);
  TextStyle get erpSelectLabel => erpLabel.copyWith(fontWeight: FontWeight.w500);
  TextStyle get erpSelectValue => erpLabel.copyWith(fontWeight: FontWeight.w500);
  TextStyle get erpMenuItem => erpTabLabel.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.2,
      );
  TextStyle get erpMenuItemActive => erpMenuItem.copyWith(
        fontWeight: FontWeight.w600,
      );
  TextStyle get erpBody => bodyLarge ?? const TextStyle();
  TextStyle get erpBodyMedium => erpBody.copyWith(fontWeight: FontWeight.w500);
  TextStyle get erpBodyStrong => erpBody.copyWith(fontWeight: FontWeight.w600);
  TextStyle get erpBodySecondary => bodyMedium ?? const TextStyle();
  TextStyle get erpCaption => bodySmall ?? const TextStyle();
  TextStyle get erpOverline => (labelSmall ?? const TextStyle()).copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        height: 1.2,
      );

  /// Tipografia de tabelas — alinhada à sidebar ([erpTabLabel], 14px).
  TextStyle get erpTableHeader => erpTabLabel.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.25,
      );

  TextStyle get erpTablePrimary => erpTabLabel.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.25,
      );

  TextStyle get erpTableSecondary => erpTabLabel.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.25,
      );

  /// Texto auxiliar em tabelas/paginação (13px).
  TextStyle get erpTableMeta => erpBodySecondary.copyWith(height: 1.3);
}
