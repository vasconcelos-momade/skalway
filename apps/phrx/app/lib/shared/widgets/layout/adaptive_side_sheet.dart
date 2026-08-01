import 'package:flutter/material.dart';

import '../../../core/theme/design_metrics.dart';
import '../dialogs/enterprise_overlay_tokens.dart';
import '../dialogs/enterprise_side_sheet.dart';

/// Largura do painel lateral — alinhada ao side sheet de categorias.
abstract final class AdaptiveSideSheetMetrics {
  AdaptiveSideSheetMetrics._();

  static const double mobileBreakpoint = DesignMetrics.overlayMobileBreakpoint;
  static const double desktopBreakpoint = DesignMetrics.overlayDesktopBreakpoint;

  /// Tablet / < desktop — mesmo valor que categorias (480).
  static const double tabletWidth = DesignMetrics.sideSheetFormTablet;

  /// Desktop — mesmo valor que categorias (520).
  static const double desktopWidth = DesignMetrics.sideSheetFormDesktop;

  static const double backdropOpacity = DesignMetrics.overlayScrimOpacity;

  /// Largura canónica para todos os side sheets de formulário.
  static double panelWidthForScreen(double screenWidth) {
    if (screenWidth >= desktopBreakpoint) return desktopWidth;
    return tabletWidth;
  }

  /// Resolve a partir do [BuildContext].
  static double panelWidthOf(BuildContext context) =>
      panelWidthForScreen(MediaQuery.sizeOf(context).width);
}

/// Side Sheet adaptativo — delega para [EnterpriseSideSheet].
class AdaptiveSideSheet {
  AdaptiveSideSheet._();

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    double? width,
    bool barrierDismissible = true,
  }) {
    return EnterpriseSideSheet.show<T>(
      context: context,
      builder: builder,
      width: width ?? AdaptiveSideSheetMetrics.panelWidthOf(context),
      size: EnterpriseOverlaySize.medium,
      barrierDismissible: barrierDismissible,
    );
  }
}

/// Fecha o side sheet activo (se existir) com resultado opcional.
Future<void> closeAdaptiveSideSheet<T>(BuildContext context, [T? result]) {
  return closeEnterpriseSideSheet<T>(context, result);
}

/// Indica se o [context] está dentro de um side sheet enterprise/adaptativo.
bool isInsideAdaptiveSideSheet(BuildContext context) {
  return isInsideEnterpriseSideSheet(context);
}
