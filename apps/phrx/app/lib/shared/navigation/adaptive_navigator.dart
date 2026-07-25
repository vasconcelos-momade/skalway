import 'package:flutter/material.dart';

import '../../core/theme/extensions.dart';
import '../widgets/dialogs/enterprise_dialog.dart';
import '../widgets/dialogs/enterprise_overlay_tokens.dart';
import '../widgets/dialogs/enterprise_side_sheet.dart';
import '../widgets/layout/adaptive_side_sheet.dart';

/// Callback para construir painéis de detalhe / histórico.
typedef AdaptiveDetailBuilder = Widget Function(
  BuildContext context,
  VoidCallback onClose,
);

/// Callback para construir formulários em modo incorporado (sem container).
typedef AdaptiveEmbeddedFormBuilder = Widget Function(
  BuildContext context, {
  required bool embedded,
});

/// Navegação adaptativa conforme o padrão do ERP / Design System.
///
/// Mobile → página ou Bottom Sheet · Tablet → Side Sheet · Desktop → Dialog / Side Sheet.
abstract final class AdaptiveNavigator {
  AdaptiveNavigator._();

  static const double _mobileBreakpoint = AdaptiveSideSheetMetrics.mobileBreakpoint;

  static double widthOf(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isMobile(BuildContext context) =>
      widthOf(context) < _mobileBreakpoint;

  static bool isDesktop(BuildContext context) =>
      widthOf(context) >= Breakpoints.desktop;

  static bool isTablet(BuildContext context) =>
      !isMobile(context) && !isDesktop(context);

  static bool useSideSheet(BuildContext context) => !isMobile(context);

  /// Completa formulário / painel (Dialog, Side Sheet ou rota mobile).
  static void complete<T>(BuildContext context, [T? result]) {
    if (isInsideAdaptiveSideSheet(context)) {
      closeAdaptiveSideSheet<T>(context, result);
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop<T>(result);
    }
  }

  /// Cancela formulário / painel actual.
  static void cancel(BuildContext context) => complete<void>(context);

  /// Detalhes / Histórico — Side Sheet (tablet/desktop) ou página (mobile).
  static Future<T?> openPanel<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    double? sideSheetWidth,
    bool barrierDismissible = true,
    RouteSettings? routeSettings,
  }) {
    return open<T>(
      context: context,
      builder: builder,
      sideSheetWidth: sideSheetWidth,
      barrierDismissible: barrierDismissible,
      routeSettings: routeSettings,
    );
  }

  /// Detalhe com [Scaffold] automático no mobile.
  static Future<void> openDetail({
    required BuildContext context,
    required String title,
    required AdaptiveDetailBuilder builder,
    RouteSettings? routeSettings,
    double? sideSheetWidth,
    bool barrierDismissible = true,
  }) {
    return openPanel<void>(
      context: context,
      routeSettings: routeSettings,
      sideSheetWidth: sideSheetWidth,
      barrierDismissible: barrierDismissible,
      builder: (detailContext) {
        void onClose() => close(detailContext);
        if (isMobile(detailContext)) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: builder(detailContext, onClose),
          );
        }
        return builder(detailContext, onClose);
      },
    );
  }

  /// Novo / Editar — Dialog (desktop), Side Sheet (tablet) ou página (mobile).
  static Future<T?> openForm<T>({
    required BuildContext context,
    required Widget title,
    required WidgetBuilder contentBuilder,
    bool barrierDismissible = true,
    RouteSettings? routeSettings,
    double? sideSheetWidth,
    EnterpriseOverlaySize size = EnterpriseOverlaySize.medium,
  }) {
    if (isMobile(context)) {
      return Navigator.of(context, rootNavigator: true).push<T>(
        MaterialPageRoute<T>(
          settings: routeSettings,
          builder: contentBuilder,
        ),
      );
    }

    if (isDesktop(context)) {
      return showEnterpriseDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        title: title,
        size: size,
        body: Builder(builder: contentBuilder),
        showClose: true,
      );
    }

    return EnterpriseSideSheet.showChrome<T>(
      context: context,
      title: title,
      width: sideSheetWidth,
      size: size,
      barrierDismissible: barrierDismissible,
      body: Builder(builder: contentBuilder),
    );
  }

  /// Formulário com corpo incorporável (sem dialog duplicado).
  static Future<T?> openEmbeddedForm<T>({
    required BuildContext context,
    required Widget title,
    required AdaptiveEmbeddedFormBuilder formBuilder,
    RouteSettings? routeSettings,
    double? sideSheetWidth,
    bool barrierDismissible = true,
    bool mobileWrapInScrollView = true,
    EnterpriseOverlaySize size = EnterpriseOverlaySize.medium,
  }) {
    return openForm<T>(
      context: context,
      title: title,
      routeSettings: routeSettings,
      sideSheetWidth: sideSheetWidth,
      barrierDismissible: barrierDismissible,
      size: size,
      contentBuilder: (formContext) {
        final form = formBuilder(formContext, embedded: true);
        if (isMobile(formContext)) {
          final body = mobileWrapInScrollView
              ? SingleChildScrollView(
                  padding: EdgeInsets.all(context.spacing.lg),
                  child: form,
                )
              : Padding(
                  padding: EdgeInsets.all(context.spacing.lg),
                  child: form,
                );
          return Scaffold(
            appBar: AppBar(
              title: title is Text ? title : const Text('Formulário'),
            ),
            body: body,
          );
        }
        return form;
      },
    );
  }

  /// Desktop/Tablet → [EnterpriseSideSheet]; Mobile → push no [rootNavigator].
  static Future<T?> open<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    double? sideSheetWidth,
    bool barrierDismissible = true,
    RouteSettings? routeSettings,
    bool fullscreenDialog = false,
    EnterpriseOverlaySize size = EnterpriseOverlaySize.medium,
  }) {
    if (useSideSheet(context)) {
      return EnterpriseSideSheet.show<T>(
        context: context,
        builder: builder,
        width: sideSheetWidth,
        size: size,
        barrierDismissible: barrierDismissible,
      );
    }

    return Navigator.of(context, rootNavigator: true).push<T>(
      MaterialPageRoute<T>(
        settings: routeSettings,
        fullscreenDialog: fullscreenDialog,
        builder: builder,
      ),
    );
  }

  /// Fecha a rota actual, side sheet ou dialog.
  static void close<T>(BuildContext context, [T? result]) {
    if (isInsideAdaptiveSideSheet(context)) {
      closeAdaptiveSideSheet<T>(context, result);
      return;
    }
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop<T>(result);
    } else {
      Navigator.of(context).maybePop<T>(result);
    }
  }
}
