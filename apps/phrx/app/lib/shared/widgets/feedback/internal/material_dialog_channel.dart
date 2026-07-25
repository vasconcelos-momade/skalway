import 'package:flutter/material.dart';

import '../../dialogs/pharma_responsive_dialog.dart';

/// Canal interno de diálogos Material responsivos.
abstract final class MaterialDialogChannel {
  MaterialDialogChannel._();

  static Future<T?> showForm<T>({
    required BuildContext context,
    required Widget title,
    required Widget content,
    List<Widget>? actions,
    bool scrollable = true,
    bool barrierDismissible = true,
  }) {
    return showPharmaResponsiveDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => PharmaResponsiveDialog(
        title: title,
        content: content,
        actions: actions,
        scrollable: scrollable,
      ),
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
  }) async {
    final result = await showForm<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      title: Text(title),
      content: content,
      scrollable: true,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                )
              : null,
          child: Text(confirmText),
        ),
      ],
    );

    return result == true;
  }
}
