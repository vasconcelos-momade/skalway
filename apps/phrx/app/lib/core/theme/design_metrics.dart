export 'spacing.dart';
export 'spacing_tokens.dart';
export 'radius.dart';
export 'elevation.dart';
export 'shadows.dart';
export 'motion.dart';
export 'breakpoints.dart';
export 'width_tokens.dart';

import 'breakpoints.dart';
import 'spacing_tokens.dart';

/// Métricas estruturais do ERP (altura de componentes, sidebars, touch targets).
abstract final class DesignMetrics {
  DesignMetrics._();

  // Touch targets MD3
  static const double minTouchTarget = 48;

  /// Altura padrão de todos os controlos de formulário e botões primários/secundários.
  /// Centralizada: alterar aqui afecta todo o Design System uniformemente.
  static const double controlHeight = minTouchTarget;

  /// Altura compacta (botões de tabelas, paginações, ações secundárias discretas).
  static const double compactControlHeight = 40;

  static const double iconMd = 24;
  static const double iconSm = 18;
  static const double avatarMd = compactControlHeight;

  static const double buttonIconSize = iconSm;
  static const double buttonLoaderSize = iconSm;
  static const double buttonLoaderStrokeWidth = 2;
  static const double feedbackIconSize = iconMd;

  // Alturas de componentes (MD3 / prompt ERP)
  /// ⚠️ Aliases legados — usar [controlHeight] em novo código.
  /// Altura visual partilhada por campos e botões de acção.
  static const double fieldHeightMin = controlHeight;
  static const double fieldHeightMax = controlHeight + 4;
  /// ⚠️ Alias legado — usar [controlHeight] em novo código.
  static const double buttonHeight = controlHeight;
  static const double tabHeightMin = 44;
  static const double tabHeightMax = minTouchTarget;
  /// ⚠️ Alias legado — usar [controlHeight] em novo código.
  static const double toolbarHeight = controlHeight;
  static const double tableRowHeightMin = 52;
  static const double tableRowHeightMax = 56;
  /// Botões circulares de paginação / segmentos.
  static const double paginationButtonSize = compactControlHeight;

  /// Controlo compacto (ex.: toggle da sidebar).
  static const double iconButtonCompactSize = compactControlHeight - 8;

  /// Largura máxima do campo de pesquisa em toolbars (design system).
  static const double searchFieldMaxWidthDesktop = 320;
  static const double searchFieldMaxWidthTablet = 300;

  // Shell / layout
  static const double topBarDesktop = 72;
  static const double topBarCompact = 56;
  static const double posFooter = minTouchTarget;

  /// Chrome do PDV: controlHeight + padding vertical do density (md*2).
  static const double posHeader = controlHeight + SpacingTokens.md * 2;

  static const double sidebarExpanded = 256;
  /// ⚠️ Legado — o sidebar desktop é fixo; não recolher a rail inteira.
  static const double sidebarCollapsed = 88;
  static const double contentMaxWidth = 1400;

  static const double breakpointMobile = Breakpoints.mobile;
  static const double breakpointTablet = Breakpoints.tablet;
  static const double breakpointDesktop = Breakpoints.desktop;

  // Diálogos
  static const double dialogMobileHorizontalInset = SpacingTokens.lg;
  static const double dialogWidthFractionTablet = 0.88;
  static const double dialogWidthFractionDesktop = 0.5;
  static const double dialogWidthCapContentFraction = 0.45;
  static const double dialogMaxHeightFractionMobile = 0.92;
  static const double dialogMaxHeightFractionDesktop = 0.88;
  static const double dialogBodyMaxHeightFraction = 0.65;
  static const double dialogSelectableListHeightFraction = 0.32;

  /// Presets de largura enterprise (Small / Medium / Large).
  static const double dialogSizeSmall = 400;
  static const double dialogSizeMedium = 560;
  static const double dialogSizeLarge = 720;

  /// Altura máxima do menu de sugestões (typeahead / selects).
  static const double suggestionsMenuMaxHeight = 280;

  static const double sideSheetSizeSmall = 400;
  static const double sideSheetSizeMedium = 560;
  static const double sideSheetSizeLarge = 640;

  /// Opacidade do scrim (modal barrier) do Design System.
  static const double overlayScrimOpacity = 0.38;

  /// Breakpoints de overlay (alinham com AdaptiveNavigator / side sheet).
  static const double overlayMobileBreakpoint = 768;
  static const double overlayDesktopBreakpoint = 1200;
}
