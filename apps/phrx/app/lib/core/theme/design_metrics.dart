export 'spacing.dart';
export 'spacing_tokens.dart';
export 'radius.dart';
export 'radius_tokens.dart';
export 'elevation.dart';
export 'shadows.dart';
export 'shadow_tokens.dart';
export 'motion.dart';
export 'motion_tokens.dart';
export 'breakpoints.dart';
export 'width_tokens.dart';
export 'border_tokens.dart';
export 'surface_tokens.dart';
export 'typography_tokens.dart';
export 'icon_tokens.dart';
export 'table_tokens.dart';

import 'breakpoints.dart';
import 'icon_tokens.dart';
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

  static const double iconMd = IconTokens.md;
  static const double iconSm = IconTokens.sm;
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
  /// Altura canónica do AppBar / top bar / footer nav (56dp em todos os breakpoints).
  static const double appBarToolbarHeight = 56;

  /// Alias — mesma altura compacta (mobile pequeno/grande = 56).
  static const double appBarToolbarHeightCompact = appBarToolbarHeight;

  /// ⚠️ Alias — preferir [appBarToolbarHeight] em novo código.
  static const double toolbarHeight = appBarToolbarHeight;
  static const double tableRowHeightMin = 52;
  static const double tableRowHeightMax = 56;
  /// Botões circulares de paginação / segmentos.
  static const double paginationButtonSize = compactControlHeight;

  /// Controlo compacto (ex.: toggle da sidebar).
  static const double iconButtonCompactSize = compactControlHeight - 8;

  /// Largura máxima do campo de pesquisa em toolbars (design system).
  static const double searchFieldMaxWidthDesktop = 320;
  static const double searchFieldMaxWidthTablet = 300;

  // Shell / layout — AppBar e footer alinhados a 56.
  static const double topBarDesktop = appBarToolbarHeight;
  static const double topBarCompact = appBarToolbarHeight;
  static const double posFooter = minTouchTarget;

  /// Chrome PDV / Proforma — alinhado ao AppBar (56).
  static const double posHeader = appBarToolbarHeight;

  /// Altura do NavigationBar mobile (sem o inset de gestos — o Scaffold trata o Safe Area).
  static const double bottomNavHeight = appBarToolbarHeight;

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

  /// Larguras padrão de menus dropdown enterprise.
  static const double dropdownMenuWidth = 220;
  static const double dropdownMenuMinWidth = 200;

  /// Largura canónica de side sheets de formulário (= categorias).
  static const double sideSheetFormTablet = 480;
  static const double sideSheetFormDesktop = 520;

  /// Aliases — todos os form sheets usam a largura de categorias.
  static const double sideSheetSizeSmall = sideSheetFormTablet;
  static const double sideSheetSizeMedium = sideSheetFormDesktop;
  static const double sideSheetSizeLarge = sideSheetFormDesktop;

  /// Largura mínima de acções em overlays (96–112).
  static const double overlayActionMinWidth = 104;

  /// Opacidade do scrim (modal barrier) do Design System.
  static const double overlayScrimOpacity = 0.38;

  /// Breakpoints de overlay (alinham com AdaptiveNavigator / side sheet).
  static const double overlayMobileBreakpoint = 768;
  static const double overlayDesktopBreakpoint = 1200;
}
