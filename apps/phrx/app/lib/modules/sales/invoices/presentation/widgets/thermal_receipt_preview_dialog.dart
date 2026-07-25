import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';

/// Preview monospace de recibo térmico 80mm (~48 colunas).
Future<void> showThermalReceiptPreview(
  BuildContext context, {
  required String title,
  required String previewText,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final t = context.pharmaTokens;
      return PharmaResponsiveDialog(
        title: Text(title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: t.bgSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: t.border),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                previewText.isEmpty ? '(recibo vazio)' : previewText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.35,
                      color: t.textPrimary,
                      letterSpacing: 0,
                    ),
              ),
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      );
    },
  );
}
