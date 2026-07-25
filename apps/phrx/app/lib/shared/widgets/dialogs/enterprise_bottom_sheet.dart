import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';
import 'enterprise_overlay_chrome.dart';
import 'enterprise_overlay_tokens.dart';

/// Bottom sheet enterprise (mobile) com chrome do Design System.
class EnterpriseBottomSheet extends StatelessWidget {
  const EnterpriseBottomSheet({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.icon,
    this.actions = const [],
    this.scrollable = true,
    this.showClose = true,
    this.onClose,
    this.initialChildSize = 0.72,
    this.minChildSize = 0.4,
    this.maxChildSize = 0.94,
  });

  final Widget title;
  final String? subtitle;
  final IconData? icon;
  final Widget body;
  final List<Widget> actions;
  final bool scrollable;
  final bool showClose;
  final VoidCallback? onClose;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        builder: (context, scrollController) {
          return Material(
            color: t.card,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.dialog(t)),
              ),
              side: BorderSide(
                color: t.border.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.55
                      : 0.75,
                ),
              ),
            ),
            clipBehavior: Clip.antiAlias,
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          margin: EdgeInsets.only(top: s.sm),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: t.border.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      EnterpriseOverlayHeader(
                        title: title,
                        subtitle: subtitle,
                        icon: icon,
                        showClose: showClose,
                        onClose: onClose ?? () => Navigator.of(context).maybePop(),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: scrollable
                            ? SingleChildScrollView(
                                controller: scrollController,
                                padding: EdgeInsets.fromLTRB(s.lg, s.md, s.lg, s.md),
                                child: body,
                              )
                            : Padding(
                                padding: EdgeInsets.fromLTRB(s.lg, s.md, s.lg, s.md),
                                child: body,
                              ),
                      ),
                      if (actions.isNotEmpty) ...[
                        const Divider(height: 1),
                        SafeArea(
                          top: false,
                          child: EnterpriseOverlayFooter(actions: actions),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DismissIntent extends Intent {
  const _DismissIntent();
}

Future<T?> showEnterpriseBottomSheet<T>({
  required BuildContext context,
  required Widget title,
  required Widget body,
  String? subtitle,
  IconData? icon,
  List<Widget> actions = const [],
  bool scrollable = true,
  bool barrierDismissible = true,
  bool showClose = true,
  double initialChildSize = 0.72,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: barrierDismissible,
    enableDrag: barrierDismissible,
    backgroundColor: Colors.transparent,
    barrierColor: enterpriseOverlayScrim(context),
    builder: (sheetContext) => EnterpriseBottomSheet(
      title: title,
      subtitle: subtitle,
      icon: icon,
      body: body,
      actions: actions,
      scrollable: scrollable,
      showClose: showClose,
      initialChildSize: initialChildSize,
      onClose: () => Navigator.of(sheetContext).maybePop(),
    ),
  );
}
