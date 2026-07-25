import 'package:flutter/material.dart';

import '../../../core/theme/design_metrics.dart';

/// Presets de largura enterprise (Small / Medium / Large).
enum EnterpriseOverlaySize {
  small,
  medium,
  large,
}

/// Preferência de apresentação em desktop/web.
enum EnterpriseDesktopSurface {
  /// Dialog centrado.
  dialog,

  /// Painel lateral (side sheet).
  sideSheet,
}

extension EnterpriseOverlaySizeX on EnterpriseOverlaySize {
  double dialogWidth(WidthTokens widths) => switch (this) {
        EnterpriseOverlaySize.small => widths.dialogSmall,
        EnterpriseOverlaySize.medium => widths.dialogMedium,
        EnterpriseOverlaySize.large => widths.dialogLarge,
      };

  double sideSheetWidth(WidthTokens widths) => switch (this) {
        EnterpriseOverlaySize.small => widths.sideSheetSmall,
        EnterpriseOverlaySize.medium => widths.sideSheetMedium,
        EnterpriseOverlaySize.large => widths.sideSheetLarge,
      };
}

/// Cor do scrim (modal barrier) do Design System.
Color enterpriseOverlayScrim(BuildContext context) {
  return Theme.of(context).colorScheme.scrim.withValues(
        alpha: DesignMetrics.overlayScrimOpacity,
      );
}

bool enterpriseIsMobileOverlay(BuildContext context) {
  return MediaQuery.sizeOf(context).width < DesignMetrics.overlayMobileBreakpoint;
}

bool enterpriseIsDesktopOverlay(BuildContext context) {
  return MediaQuery.sizeOf(context).width >= DesignMetrics.overlayDesktopBreakpoint;
}
