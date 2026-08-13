import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/api_failure.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/dialogs/enterprise_form_side_sheet.dart';
import '../../../../shared/widgets/dialogs/enterprise_overlay_chrome.dart';
import '../../../../shared/widgets/dialogs/enterprise_side_sheet.dart';
import '../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../shared/widgets/inputs/enterprise_text_field.dart';
import '../../domain/entities/platform_entities.dart';
import '../providers/platform_providers.dart';
import 'platform_payment_method_cards.dart';

Future<bool> showConfirmPaymentSideSheet(
  BuildContext context, {
  required PlatformInvoice invoice,
}) async {
  final result = await EnterpriseSideSheet.show<bool>(
    context: context,
    barrierDismissible: false,
    builder: (sheetContext) => ConfirmPaymentSideSheet(invoice: invoice),
  );
  return result == true;
}

class ConfirmPaymentSideSheet extends ConsumerStatefulWidget {
  const ConfirmPaymentSideSheet({super.key, required this.invoice});

  final PlatformInvoice invoice;

  @override
  ConsumerState<ConfirmPaymentSideSheet> createState() =>
      _ConfirmPaymentSideSheetState();
}

class _ConfirmPaymentSideSheetState
    extends ConsumerState<ConfirmPaymentSideSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  final _referenceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _method = PlatformPaymentMethods.cash;
  String? _error;
  bool _submitting = false;

  PlatformInvoice get invoice => widget.invoice;

  @override
  void initState() {
    super.initState();
    final open = invoice.balance > 0
        ? invoice.balance
        : (invoice.payableAmount ?? invoice.total);
    _amountCtrl = TextEditingController(
      text: open > 0 ? open.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Valor recebido inválido.');
      return;
    }

    final reference = _referenceCtrl.text.trim();
    if (PlatformPaymentMethods.requiresReference(_method) &&
        reference.isEmpty) {
      setState(() => _error = 'Referência da transacção é obrigatória.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(platformBillingActionsProvider.notifier).confirmInvoicePayment(
            tenantId: invoice.tenantId,
            payload: ConfirmInvoicePaymentPayload(
              invoiceId: invoice.id,
              amount: amount,
              method: _method,
              reference: reference.isEmpty ? null : reference,
              notes: _notesCtrl.text.trim().isEmpty
                  ? null
                  : _notesCtrl.text.trim(),
            ),
          );
      if (!mounted) return;
      PharmaFeedback.success(context, 'Pagamento confirmado com sucesso.');
      await closeEnterpriseSideSheet(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e is ApiFailure ? e.message : e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'MT ', decimalDigits: 2);
    final t = context.pharmaTokens;
    final s = context.spacing;

    final body = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EnterpriseListCard(
            title: 'Tenant',
            subtitle: invoice.tenantName,
            leading: Icons.business_rounded,
          ),
          if (invoice.tenantKey != null && invoice.tenantKey!.trim().isNotEmpty)
            EnterpriseListCard(
              title: 'Identificador',
              subtitle: invoice.tenantKey!,
              leading: Icons.tag_rounded,
            ),
          EnterpriseListCard(
            title: 'Número da Factura',
            subtitle: invoice.number,
            leading: Icons.receipt_long_outlined,
          ),
          EnterpriseListCard(
            title: 'Subtotal',
            subtitle: currency.format(invoice.grossSubtotal),
            leading: Icons.receipt_outlined,
          ),
          if (invoice.discount > 0)
            EnterpriseListCard(
              title: 'Desconto',
              subtitle: currency.format(invoice.discount),
              leading: Icons.discount_outlined,
            ),
          EnterpriseListCard(
            title: 'Total',
            subtitle: currency.format(invoice.payableAmount ?? invoice.total),
            leading: Icons.payments_outlined,
          ),
          EnterpriseListCard(
            title: 'Pago',
            subtitle: currency.format(invoice.paid),
            leading: Icons.check_circle_outline,
          ),
          EnterpriseListCard(
            title: 'Em aberto',
            subtitle: currency.format(invoice.balance),
            leading: Icons.pending_actions_outlined,
          ),
          EnterpriseListCard(
            title: 'Estado',
            subtitle: invoice.status.toUpperCase(),
            leading: Icons.info_outline_rounded,
          ),
          SizedBox(height: s.md),
          Text(
            'Método de Pagamento',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          SizedBox(height: s.sm),
          PlatformPaymentMethodCards(
            value: _method,
            enabled: !_submitting,
            onChanged: (method) => setState(() => _method = method),
          ),
          SizedBox(height: s.md),
          EnterpriseTextFormField(
            controller: _referenceCtrl,
            labelText: PlatformPaymentMethods.requiresReference(_method)
                ? 'Referência da Transacção *'
                : 'Referência da Transacção',
            enabled: !_submitting,
            validator: (value) {
              if (!PlatformPaymentMethods.requiresReference(_method)) {
                return null;
              }
              if (value == null || value.trim().isEmpty) {
                return 'Obrigatória excepto para Cash.';
              }
              return null;
            },
          ),
          SizedBox(height: s.md),
          EnterpriseTextFormField(
            controller: _amountCtrl,
            labelText: 'Valor Recebido *',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            enabled: !_submitting,
            validator: (value) {
              final parsed = double.tryParse(
                (value ?? '').replaceAll(',', '.'),
              );
              if (parsed == null || parsed <= 0) {
                return 'Informe um valor positivo.';
              }
              return null;
            },
          ),
          SizedBox(height: s.md),
          EnterpriseTextFormField(
            controller: _notesCtrl,
            labelText: 'Notas',
            maxLines: 3,
            minLines: 2,
            enabled: !_submitting,
          ),
          if (_error != null) ...[
            SizedBox(height: s.md),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: t.posDanger,
                  ),
            ),
          ],
        ],
      ),
    );

    return EnterpriseFormSideSheet(
      title: const Text('Confirmar Pagamento'),
      subtitle: invoice.number,
      onClose: _submitting
          ? null
          : () => closeEnterpriseSideSheet(context, false),
      body: body,
      actions: [
        EnterpriseOverlayActions.secondary(
          label: 'Cancelar',
          onPressed: _submitting
              ? null
              : () => closeEnterpriseSideSheet(context, false),
        ),
        EnterpriseOverlayActions.primary(
          label: _submitting ? 'A confirmar…' : 'Confirmar Pagamento',
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}
