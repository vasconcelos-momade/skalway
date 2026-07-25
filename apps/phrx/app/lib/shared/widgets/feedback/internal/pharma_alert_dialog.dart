import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../buttons/pharma_button_loader.dart';
import '../../dialogs/pharma_responsive_dialog.dart';

enum _AlertVisual { confirm, error, success, warning, loading }

/// Diálogos modais de alerta/confirmação alinhados ao design system.
abstract final class PharmaAlertDialog {
  PharmaAlertDialog._();

  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    bool destructive = false,
    bool barrierDismissible = false,
  }) async {
    final result = await showPharmaResponsiveDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        final t = dialogContext.pharmaTokens;
        final s = dialogContext.spacing;
        final theme = Theme.of(dialogContext);

        return PharmaResponsiveDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AlertHeader(
                visual: _AlertVisual.confirm,
                accentColor: destructive ? t.posDanger : t.brandBlue,
              ),
              SizedBox(height: s.md),
              Text(
                message,
                style: theme.textTheme.erpBodySecondary.copyWith(color: t.textSecondary),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelText),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: destructive
                  ? FilledButton.styleFrom(backgroundColor: t.posDanger)
                  : null,
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Entendi',
  }) {
    return _showAcknowledgement(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      visual: _AlertVisual.error,
      accentColor: context.pharmaTokens.posDanger,
    );
  }

  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'OK',
  }) {
    return _showAcknowledgement(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      visual: _AlertVisual.success,
      accentColor: context.pharmaTokens.brandGreen,
    );
  }

  static Future<void> showWarning({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Continuar',
  }) {
    return _showAcknowledgement(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      visual: _AlertVisual.warning,
      accentColor: context.pharmaTokens.posWarning,
    );
  }

  static Future<void> showLoading({
    required BuildContext context,
    String title = 'A processar',
    String? message,
  }) {
    return showPharmaResponsiveDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final t = dialogContext.pharmaTokens;
        final s = dialogContext.spacing;
        final theme = Theme.of(dialogContext);

        return PharmaResponsiveDialog(
          title: Text(title),
          scrollable: false,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const PharmaButtonLoader(),
              if (message != null && message.isNotEmpty) ...[
                SizedBox(height: s.md),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.erpBodySecondary.copyWith(color: t.textSecondary),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static Future<void> _showAcknowledgement({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
    required _AlertVisual visual,
    required Color accentColor,
  }) {
    return showPharmaResponsiveDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final t = dialogContext.pharmaTokens;
        final s = dialogContext.spacing;
        final theme = Theme.of(dialogContext);

        return PharmaResponsiveDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AlertHeader(visual: visual, accentColor: accentColor),
              SizedBox(height: s.md),
              Text(
                message,
                style: theme.textTheme.erpBodySecondary.copyWith(color: t.textSecondary),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(backgroundColor: accentColor),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }
}

class _AlertHeader extends StatelessWidget {
  const _AlertHeader({
    required this.visual,
    required this.accentColor,
  });

  final _AlertVisual visual;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;

    return Align(
      child: Container(
        width: t.minTouchTarget,
        height: t.minTouchTarget,
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _iconFor(visual),
          color: accentColor,
          size: t.iconMd,
        ),
      ),
    );
  }

  IconData _iconFor(_AlertVisual visual) {
    return switch (visual) {
      _AlertVisual.confirm => Icons.help_outline_rounded,
      _AlertVisual.error => Icons.error_outline_rounded,
      _AlertVisual.success => Icons.check_circle_outline_rounded,
      _AlertVisual.warning => Icons.warning_amber_rounded,
      _AlertVisual.loading => Icons.hourglass_top_rounded,
    };
  }
}
