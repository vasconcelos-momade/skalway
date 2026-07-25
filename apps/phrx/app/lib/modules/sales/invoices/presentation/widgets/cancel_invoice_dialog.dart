import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../domain/entities/invoice_summary.dart';

Future<CancelInvoicePayload?> showCancelInvoiceDialog(
  BuildContext context, {
  required InvoiceSummary invoice,
}) {
  return AdaptiveNavigator.openEmbeddedForm<CancelInvoicePayload>(
    context: context,
    title: Text('Cancelar ${invoice.numero}'),
    routeSettings: RouteSettings(name: '/faturas/${invoice.id}/cancelar'),
    formBuilder: (ctx, {required embedded}) =>
        CancelInvoiceDialog(invoice: invoice, embedded: embedded),
  );
}

class CancelInvoiceDialog extends StatefulWidget {
  const CancelInvoiceDialog({
    super.key,
    required this.invoice,
    this.embedded = false,
  });

  final InvoiceSummary invoice;
  final bool embedded;

  @override
  State<CancelInvoiceDialog> createState() => _CancelInvoiceDialogState();
}

class _CancelInvoiceDialogState extends State<CancelInvoiceDialog> {
  late final TextEditingController _reasonController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    final form = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Esta ação deve refletir a reversão no backend. Informe o motivo do cancelamento.',
          style: Theme.of(
            context,
          ).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
        ),
        SizedBox(height: s.lg),
        TextField(
          controller: _reasonController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Motivo',
            hintText: 'Ex.: erro no caixa',
          ),
        ),
        SizedBox(height: s.md),
        TextField(
          controller: _notesController,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Observações',
            hintText: 'Opcional',
          ),
        ),
      ],
    );

    final actions = [
      Expanded(
        child: OutlinedButton(
          onPressed: () => AdaptiveNavigator.cancel(context),
          child: const Text('Fechar'),
        ),
      ),
      SizedBox(width: s.md),
      Expanded(
        flex: 2,
        child: FilledButton(
          onPressed: () {
            AdaptiveNavigator.complete(
              context,
              CancelInvoicePayload(
                motivo: _reasonController.text.trim(),
                observacoes: _notesController.text.trim().isEmpty
                    ? null
                    : _notesController.text.trim(),
              ),
            );
          },
          child: const Text('Confirmar cancelamento'),
        ),
      ),
    ];

    if (widget.embedded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          form,
          SizedBox(height: s.xl),
          Row(children: actions),
        ],
      );
    }

    final media = MediaQuery.of(context);
    return Dialog(
      backgroundColor: t.bgPrimary,
      insetPadding: EdgeInsets.symmetric(
        horizontal: media.size.width < 600 ? 16 : 32,
        vertical: media.size.width < 600 ? 24 : 40,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(t.radiusXl),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: media.size.height * 0.82,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: s.lg,
            right: s.lg,
            top: s.lg,
            bottom: media.viewInsets.bottom + s.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cancelar ${widget.invoice.numero}',
                  style: Theme.of(
                    context,
                  ).textTheme.erpCardTitle.copyWith(color: t.textPrimary),
                ),
                SizedBox(height: s.md),
                form,
                SizedBox(height: s.xl),
                Row(children: actions),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CancelInvoicePayload {
  const CancelInvoicePayload({required this.motivo, this.observacoes});

  final String motivo;
  final String? observacoes;
}
