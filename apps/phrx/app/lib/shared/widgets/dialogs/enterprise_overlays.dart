import 'package:flutter/material.dart';

import 'enterprise_bottom_sheet.dart';
import 'enterprise_dialog.dart';
import 'enterprise_overlay_tokens.dart';
import 'enterprise_side_sheet.dart';

export 'enterprise_bottom_sheet.dart';
export 'enterprise_dialog.dart';
export 'enterprise_overlay_chrome.dart';
export 'enterprise_overlay_tokens.dart';
export 'enterprise_side_sheet.dart';

/// API unificada: Mobile → BottomSheet, Tablet → Dialog, Desktop → Dialog ou SideSheet.
abstract final class EnterpriseOverlay {
  EnterpriseOverlay._();

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget title,
    required Widget body,
    String? subtitle,
    IconData? icon,
    List<Widget> actions = const [],
    EnterpriseOverlaySize size = EnterpriseOverlaySize.medium,
    EnterpriseDesktopSurface desktopSurface = EnterpriseDesktopSurface.dialog,
    bool scrollable = true,
    bool barrierDismissible = true,
    bool showClose = true,
  }) {
    if (enterpriseIsMobileOverlay(context)) {
      return showEnterpriseBottomSheet<T>(
        context: context,
        title: title,
        subtitle: subtitle,
        icon: icon,
        body: body,
        actions: actions,
        scrollable: scrollable,
        barrierDismissible: barrierDismissible,
        showClose: showClose,
      );
    }

    if (enterpriseIsDesktopOverlay(context) &&
        desktopSurface == EnterpriseDesktopSurface.sideSheet) {
      return EnterpriseSideSheet.showChrome<T>(
        context: context,
        title: title,
        subtitle: subtitle,
        icon: icon,
        body: body,
        actions: actions,
        size: size,
        scrollable: scrollable,
        barrierDismissible: barrierDismissible,
        showClose: showClose,
      );
    }

    // Tablet e desktop (dialog).
    return showEnterpriseDialog<T>(
      context: context,
      title: title,
      subtitle: subtitle,
      icon: icon,
      body: body,
      actions: actions,
      size: size,
      scrollable: scrollable,
      barrierDismissible: barrierDismissible,
      showClose: showClose,
    );
  }
}
