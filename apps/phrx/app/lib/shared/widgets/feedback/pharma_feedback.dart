import 'package:flutter/material.dart';

import 'internal/material_dialog_channel.dart';
import 'internal/quick_alert_channel.dart';
import 'notification_service.dart';

/// Fachada única de feedback do utilizador.
///
/// Os módulos devem usar apenas esta API — nunca importar QuickAlert directamente.
///
/// | Tipo | Método | Canal |
/// |------|--------|-------|
/// | Sucesso rápido | [success] | NotificationService |
/// | Erro rápido | [error] | NotificationService |
/// | Info / aviso leve | [info] / [warning] | NotificationService |
/// | Confirmação | [confirm] | QuickAlert (interno) |
/// | Erro crítico | [criticalError] | QuickAlert (interno) |
/// | Aviso modal | [alertWarning] | QuickAlert (interno) |
/// | Sucesso modal | [alertSuccess] | QuickAlert (interno) |
/// | Loading | [loading] / [dismiss] | QuickAlert (interno) |
/// | Formulário | [showForm] | Dialog Material |
/// | Confirmação complexa | [confirmComplex] | Dialog Material |
abstract final class PharmaFeedback {
  PharmaFeedback._();

  // ── SnackBar (notificações rápidas) ──────────────────────────────────────

  static void success(BuildContext context, String message) =>
      NotificationService.success(context, message);

  static void error(BuildContext context, String message) =>
      NotificationService.error(context, message);

  static void info(BuildContext context, String message) =>
      NotificationService.info(context, message);

  static void warning(BuildContext context, String message) =>
      NotificationService.warning(context, message);

  // ── QuickAlert (modais — via adaptador interno) ──────────────────────────

  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    bool destructive = false,
    bool barrierDismissible = false,
  }) {
    return QuickAlertChannel.confirm(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      destructive: destructive,
      barrierDismissible: barrierDismissible,
    );
  }

  static Future<void> criticalError({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Entendi',
  }) {
    return QuickAlertChannel.showError(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
    );
  }

  static Future<void> alertSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'OK',
  }) {
    return QuickAlertChannel.showSuccess(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
    );
  }

  static Future<void> alertWarning({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Continuar',
  }) {
    return QuickAlertChannel.showWarning(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
    );
  }

  static Future<void> loading({
    required BuildContext context,
    String title = 'A processar',
    String? message,
  }) {
    return QuickAlertChannel.showLoading(
      context: context,
      title: title,
      message: message,
    );
  }

  static void dismiss(BuildContext context) =>
      QuickAlertChannel.dismiss(context);

  // ── Dialog Material (formulários e confirmações complexas) ───────────────

  static Future<T?> showForm<T>({
    required BuildContext context,
    required Widget title,
    required Widget content,
    List<Widget>? actions,
    bool scrollable = true,
    bool barrierDismissible = true,
  }) {
    return MaterialDialogChannel.showForm<T>(
      context: context,
      title: title,
      content: content,
      actions: actions,
      scrollable: scrollable,
      barrierDismissible: barrierDismissible,
    );
  }

  static Future<bool> confirmComplex({
    required BuildContext context,
    required String title,
    required Widget content,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    bool destructive = false,
    bool barrierDismissible = false,
  }) {
    return MaterialDialogChannel.confirmComplex(
      context: context,
      title: title,
      content: content,
      confirmText: confirmText,
      cancelText: cancelText,
      destructive: destructive,
      barrierDismissible: barrierDismissible,
    );
  }
}
