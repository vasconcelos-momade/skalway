import 'package:flutter/material.dart';

import '../../../core/theme/design_metrics.dart';
import 'enterprise_dialog.dart';
import 'enterprise_overlay_chrome.dart';
import 'enterprise_overlay_tokens.dart';

enum PharmaDialogBreakpoint {
  mobile,
  tablet,
  desktop,
}

PharmaDialogBreakpoint pharmaDialogBreakpointForWidth(double width) {
  if (width < DesignMetrics.overlayMobileBreakpoint) {
    return PharmaDialogBreakpoint.mobile;
  }
  if (width < DesignMetrics.overlayDesktopBreakpoint) {
    return PharmaDialogBreakpoint.tablet;
  }
  return PharmaDialogBreakpoint.desktop;
}

/// Compatibilidade: dialog responsivo baseado em [EnterpriseDialog].
class PharmaResponsiveDialog extends StatelessWidget {
  const PharmaResponsiveDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.scrollable = true,
  });

  final Widget title;
  final Widget content;
  final List<Widget>? actions;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return EnterpriseDialog(
      title: title,
      body: content,
      actions: actions ?? const [],
      scrollable: scrollable,
      size: EnterpriseOverlaySize.medium,
      showClose: false,
    );
  }
}

/// Ações: layout enterprise no rodapé.
class PharmaResponsiveDialogActions extends StatelessWidget {
  const PharmaResponsiveDialogActions({
    super.key,
    required this.children,
    required this.breakpoint,
  });

  final List<Widget> children;
  final PharmaDialogBreakpoint breakpoint;

  @override
  Widget build(BuildContext context) {
    return EnterpriseOverlayFooter(
      actions: children,
      expandOnNarrow: breakpoint == PharmaDialogBreakpoint.mobile,
    );
  }
}

Future<T?> showPharmaResponsiveDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: enterpriseOverlayScrim(context),
    builder: builder,
  );
}
