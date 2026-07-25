import 'package:flutter/material.dart';

import 'internal/notification_type.dart';
import 'widgets/enterprise_snackbar.dart';

abstract class NotificationService {
  NotificationService._();

  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required NotificationType type,
    required String message,
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final duration = switch (type) {
      NotificationType.success => const Duration(milliseconds: 1200),
      NotificationType.info => const Duration(milliseconds: 1500),
      NotificationType.warning => const Duration(milliseconds: 2200),
      NotificationType.error => const Duration(milliseconds: 3000),
    };

    _currentEntry = OverlayEntry(
      builder: (context) => EnterpriseSnackbar(
        type: type,
        message: message,
        duration: duration,
        onClose: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
      ),
    );

    overlay.insert(_currentEntry!);
  }

  static void success(BuildContext context, String message) =>
      show(context, type: NotificationType.success, message: message);

  static void error(BuildContext context, String message) =>
      show(context, type: NotificationType.error, message: message);

  static void warning(BuildContext context, String message) =>
      show(context, type: NotificationType.warning, message: message);

  static void info(BuildContext context, String message) =>
      show(context, type: NotificationType.info, message: message);
}