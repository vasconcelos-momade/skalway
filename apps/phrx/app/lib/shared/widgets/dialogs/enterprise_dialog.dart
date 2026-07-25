import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/design_metrics.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';
import 'enterprise_overlay_chrome.dart';
import 'enterprise_overlay_tokens.dart';

/// Dialog enterprise centrado (tablet/desktop) com chrome do Design System.
class EnterpriseDialog extends StatelessWidget {
  const EnterpriseDialog({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.icon,
    this.actions = const [],
    this.size = EnterpriseOverlaySize.medium,
    this.scrollable = true,
    this.showClose = true,
    this.onClose,
  });

  final Widget title;
  final String? subtitle;
  final IconData? icon;
  final Widget body;
  final List<Widget> actions;
  final EnterpriseOverlaySize size;
  final bool scrollable;
  final bool showClose;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final widths = context.widths;
    final screen = MediaQuery.sizeOf(context);
    final isNarrow = screen.width < Breakpoints.tablet;

    final horizontalInset = isNarrow
        ? DesignMetrics.dialogMobileHorizontalInset
        : s.lg;
    final availableWidth = screen.width - (horizontalInset * 2);
    final preferredWidth = size.dialogWidth(widths);
    final maxWidth = preferredWidth < availableWidth ? preferredWidth : availableWidth;
    final maxHeight = screen.height *
        (isNarrow
            ? DesignMetrics.dialogMaxHeightFractionMobile
            : DesignMetrics.dialogMaxHeightFractionDesktop);

    final Widget bodySection;
    if (scrollable) {
      bodySection = ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight * DesignMetrics.dialogBodyMaxHeightFraction,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(s.lg, s.sm, s.lg, s.md),
          child: body,
        ),
      );
    } else {
      bodySection = Padding(
        padding: EdgeInsets.fromLTRB(s.lg, s.sm, s.lg, s.md),
        child: body,
      );
    }

    return Dialog(
      backgroundColor: t.card,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: isNarrow ? s.lg : s.xxl,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog(t)),
        side: BorderSide(
          color: t.border.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? 0.6 : 0.85,
          ),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.dialog(t)),
            boxShadow: AppShadows.dialog(context),
          ),
          child: Material(
            color: t.card,
            child: Shortcuts(
              shortcuts: const {
                SingleActivator(LogicalKeyboardKey.escape): _DismissIntent(),
              },
              child: Actions(
                actions: {
                  _DismissIntent: CallbackAction<_DismissIntent>(
                    onInvoke: (_) {
                      (onClose ?? () => Navigator.of(context).maybePop())();
                      return null;
                    },
                  ),
                },
                child: Focus(
                  autofocus: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      EnterpriseOverlayHeader(
                        title: title,
                        subtitle: subtitle,
                        icon: icon,
                        showClose: showClose,
                        onClose: onClose ?? () => Navigator.of(context).maybePop(),
                      ),
                      const Divider(height: 1),
                      bodySection,
                      if (actions.isNotEmpty) ...[
                        const Divider(height: 1),
                        EnterpriseOverlayFooter(actions: actions),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DismissIntent extends Intent {
  const _DismissIntent();
}

Future<T?> showEnterpriseDialog<T>({
  required BuildContext context,
  required Widget title,
  required Widget body,
  String? subtitle,
  IconData? icon,
  List<Widget> actions = const [],
  EnterpriseOverlaySize size = EnterpriseOverlaySize.medium,
  bool scrollable = true,
  bool barrierDismissible = true,
  bool showClose = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: enterpriseOverlayScrim(context),
    builder: (dialogContext) => EnterpriseDialog(
      title: title,
      subtitle: subtitle,
      icon: icon,
      body: body,
      actions: actions,
      size: size,
      scrollable: scrollable,
      showClose: showClose,
      onClose: () => Navigator.of(dialogContext).maybePop(),
    ),
  );
}
