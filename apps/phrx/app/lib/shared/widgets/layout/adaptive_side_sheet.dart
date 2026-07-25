import 'package:flutter/material.dart';

import '../../../core/theme/design_metrics.dart';
import '../dialogs/enterprise_overlay_tokens.dart';
import '../dialogs/enterprise_side_sheet.dart';

/// Largura do painel lateral conforme o Design System.
abstract final class AdaptiveSideSheetMetrics {
  AdaptiveSideSheetMetrics._();

  static const double mobileBreakpoint = DesignMetrics.overlayMobileBreakpoint;
  static const double desktopBreakpoint = DesignMetrics.overlayDesktopBreakpoint;
  static const double tabletWidth = DesignMetrics.sideSheetSizeMedium;
  static const double desktopWidth = DesignMetrics.sideSheetSizeLarge;
  static const double backdropOpacity = DesignMetrics.overlayScrimOpacity;

  static double panelWidthForScreen(double screenWidth) {
    if (screenWidth >= desktopBreakpoint) return desktopWidth;
    return tabletWidth;
  }
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
      width: width ??
          AdaptiveSideSheetMetrics.panelWidthForScreen(
            MediaQuery.sizeOf(context).width,
          ),
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
