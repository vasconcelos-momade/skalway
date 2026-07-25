import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/design_metrics.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';
import 'enterprise_overlay_chrome.dart';
import 'enterprise_overlay_tokens.dart';

/// Side sheet enterprise (tablet/desktop) com chrome e animação do Design System.
abstract final class EnterpriseSideSheet {
  EnterpriseSideSheet._();

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    EnterpriseOverlaySize size = EnterpriseOverlaySize.medium,
    double? width,
    bool barrierDismissible = true,
  }) {
    final widths = context.widths;
    final resolvedWidth = width ??
        size.sideSheetWidth(widths).clamp(
              DesignMetrics.sideSheetSizeSmall,
              DesignMetrics.sideSheetSizeLarge,
            );

    final overlay = Overlay.of(context, rootOverlay: true);
    final completer = Completer<T?>();
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (overlayContext) => _EnterpriseSideSheetOverlay<T>(
        width: resolvedWidth.toDouble(),
        barrierDismissible: barrierDismissible,
        onClosed: (result) {
          entry.remove();
          if (!completer.isCompleted) {
            completer.complete(result);
          }
        },
        child: Builder(builder: builder),
      ),
    );

    overlay.insert(entry);
    return completer.future;
  }

  /// Variante com cabeçalho/rodapé padronizados.
  static Future<T?> showChrome<T>({
    required BuildContext context,
    required Widget title,
    required Widget body,
    String? subtitle,
    IconData? icon,
    List<Widget> actions = const [],
    EnterpriseOverlaySize size = EnterpriseOverlaySize.medium,
    double? width,
    bool barrierDismissible = true,
    bool scrollable = true,
    bool showClose = true,
  }) {
    return show<T>(
      context: context,
      size: size,
      width: width,
      barrierDismissible: barrierDismissible,
      builder: (sheetContext) => EnterpriseSideSheetFrame(
        title: title,
        subtitle: subtitle,
        icon: icon,
        body: body,
        actions: actions,
        scrollable: scrollable,
        showClose: showClose,
        onClose: () => closeEnterpriseSideSheet<T>(sheetContext),
      ),
    );
  }
}

/// Conteúdo padrão de um side sheet enterprise.
class EnterpriseSideSheetFrame extends StatelessWidget {
  const EnterpriseSideSheetFrame({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.icon,
    this.actions = const [],
    this.scrollable = true,
    this.showClose = true,
    this.onClose,
  });

  final Widget title;
  final String? subtitle;
  final IconData? icon;
  final Widget body;
  final List<Widget> actions;
  final bool scrollable;
  final bool showClose;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): _DismissIntent(),
      },
      child: Actions(
        actions: {
          _DismissIntent: CallbackAction<_DismissIntent>(
            onInvoke: (_) {
              (onClose ?? () => closeEnterpriseSideSheet(context))();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EnterpriseOverlayHeader(
                title: title,
                subtitle: subtitle,
                icon: icon,
                showClose: showClose,
                onClose: onClose ?? () => closeEnterpriseSideSheet(context),
              ),
              const Divider(height: 1),
              Expanded(
                child: scrollable
                    ? SingleChildScrollView(
                        padding: EdgeInsets.all(s.lg),
                        child: body,
                      )
                    : Padding(
                        padding: EdgeInsets.all(s.lg),
                        child: body,
                      ),
              ),
              if (actions.isNotEmpty) ...[
                const Divider(height: 1),
                EnterpriseOverlayFooter(actions: actions),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DismissIntent extends Intent {
  const _DismissIntent();
}

class _EnterpriseSideSheetOverlay<T> extends StatefulWidget {
  const _EnterpriseSideSheetOverlay({
    required this.width,
    required this.barrierDismissible,
    required this.onClosed,
    required this.child,
  });

  final double width;
  final bool barrierDismissible;
  final void Function(T? result) onClosed;
  final Widget child;

  @override
  State<_EnterpriseSideSheetOverlay<T>> createState() =>
      _EnterpriseSideSheetOverlayState<T>();
}

class _EnterpriseSideSheetOverlayState<T>
    extends State<_EnterpriseSideSheetOverlay<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Motion.durationNormal,
      reverseDuration: Motion.durationFast,
    );
    _slide = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Motion.emphasized));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close([T? result]) async {
    if (_closing) return;
    _closing = true;
    await _controller.reverse();
    widget.onClosed(result);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final scheme = Theme.of(context).colorScheme;
    final elevation = context.elevationTokens.level8;

    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeOut,
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.barrierDismissible ? () => _close() : null,
                  child: ColoredBox(color: enterpriseOverlayScrim(context)),
                ),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: SlideTransition(
                  position: _slide,
                  child: SafeArea(
                    child: SizedBox(
                      width: widget.width,
                      height: double.infinity,
                      child: Material(
                        color: t.bgPrimary,
                        elevation: elevation,
                        shadowColor: scheme.shadow.withValues(alpha: 0.22),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: t.bgPrimary,
                            border: Border(
                              left: BorderSide(
                                color: t.border.withValues(alpha: 0.45),
                              ),
                            ),
                            boxShadow: AppShadows.dialog(context),
                          ),
                          child: Navigator(
                            onGenerateRoute: (_) => MaterialPageRoute<void>(
                              builder: (_) => _EnterpriseSideSheetScope(
                                close: ([result]) => _close(result as T?),
                                child: widget.child,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnterpriseSideSheetScope extends InheritedWidget {
  const _EnterpriseSideSheetScope({
    required this.close,
    required super.child,
  });

  final Future<void> Function([Object? result]) close;

  static _EnterpriseSideSheetScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_EnterpriseSideSheetScope>();
  }

  @override
  bool updateShouldNotify(_EnterpriseSideSheetScope oldWidget) => false;
}

Future<void> closeEnterpriseSideSheet<T>(BuildContext context, [T? result]) {
  final scope = _EnterpriseSideSheetScope.maybeOf(context);
  return scope?.close(result) ?? Future.value();
}

bool isInsideEnterpriseSideSheet(BuildContext context) {
  return _EnterpriseSideSheetScope.maybeOf(context) != null;
}
