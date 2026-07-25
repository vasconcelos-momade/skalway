import 'package:flutter/material.dart';

import 'pharma_alert_dialog.dart';

/// Adaptador interno de alertas modais — delega ao design system (sem QuickAlert).
abstract final class QuickAlertChannel {
  QuickAlertChannel._();

  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    bool destructive = false,
    bool barrierDismissible = false,
  }) {
    return PharmaAlertDialog.confirm(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      destructive: destructive,
      barrierDismissible: barrierDismissible,
    );
  }

  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Entendi',
  }) {
    return PharmaAlertDialog.showError(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
    );
  }

  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'OK',
  }) {
    return PharmaAlertDialog.showSuccess(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
    );
  }

  static Future<void> showWarning({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Continuar',
  }) {
    return PharmaAlertDialog.showWarning(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
    );
  }

  static Future<void> showLoading({
    required BuildContext context,
    String title = 'A processar',
    String? message,
  }) {
    return PharmaAlertDialog.showLoading(
      context: context,
      title: title,
      message: message,
    );
  }

  static void dismiss(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}
