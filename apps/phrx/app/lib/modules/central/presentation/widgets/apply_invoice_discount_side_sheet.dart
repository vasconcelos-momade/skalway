import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/api_failure.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/dialogs/enterprise_form_side_sheet.dart';
import '../../../../shared/widgets/dialogs/enterprise_overlay_chrome.dart';
import '../../../../shared/widgets/dialogs/enterprise_side_sheet.dart';
import '../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../shared/widgets/inputs/enterprise_text_field.dart';
import '../../domain/entities/platform_entities.dart';
import '../providers/platform_providers.dart';

Future<bool> showApplyInvoiceDiscountSideSheet(
  BuildContext context, {
  required PlatformInvoice invoice,
}) async {
  final result = await EnterpriseSideSheet.show<bool>(
    context: context,
    barrierDismissible: false,
    builder: (sheetContext) => ApplyInvoiceDiscountSideSheet(invoice: invoice),
  );
  return result == true;
}

class ApplyInvoiceDiscountSideSheet extends ConsumerStatefulWidget {
  const ApplyInvoiceDiscountSideSheet({super.key, required this.invoice});

  final PlatformInvoice invoice;

  @override
  ConsumerState<ApplyInvoiceDiscountSideSheet> createState() =>
      _ApplyInvoiceDiscountSideSheetState();
}

class _ApplyInvoiceDiscountSideSheetState
    extends ConsumerState<ApplyInvoiceDiscountSideSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _discountCtrl;
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;

  PlatformInvoice get invoice => widget.invoice;

  @override
  void initState() {
    super.initState();
    _discountCtrl = TextEditingController(
      text: invoice.discount > 0
          ? invoice.discount.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final discount = double.tryParse(
          _discountCtrl.text.trim().replaceAll(',', '.'),
        ) ??
        -1;
    setState(() => _submitting = true);
    try {
      await ref.read(platformBillingActionsProvider.notifier).applyInvoiceDiscount(
            tenantId: invoice.tenantId,
            invoiceId: invoice.id,
            discount: discount,
            reason: _reasonCtrl.text.trim().isEmpty
                ? null
                : _reasonCtrl.text.trim(),
          );
      if (!mounted) return;
      PharmaFeedback.success(context, 'Desconto aplicado.');
      closeEnterpriseSideSheet(context, true);
    } catch (e) {
      if (!mounted) return;
      PharmaFeedback.error(
        context,
        e is ApiFailure ? e.message : e.toString(),
      );
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'MT ', decimalDigits: 2);
    final s = context.spacing;
    final maxDiscount = invoice.grossSubtotal;

    return EnterpriseFormSideSheet(
      title: const Text('Adicionar desconto'),
      subtitle: invoice.number,
      onClose: _submitting
          ? null
          : () => closeEnterpriseSideSheet(context, false),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EnterpriseListCard(
              title: 'Tenant',
              subtitle: invoice.tenantName,
              leading: Icons.business_rounded,
            ),
            EnterpriseListCard(
              title: 'Subtotal',
              subtitle: currency.format(invoice.grossSubtotal),
              leading: Icons.payments_outlined,
            ),
            if (invoice.paid > 0)
              EnterpriseListCard(
                title: 'Já pago',
                subtitle: currency.format(invoice.paid),
                leading: Icons.check_circle_outline,
              ),
            SizedBox(height: s.md),
            EnterpriseTextFormField(
              controller: _discountCtrl,
              labelText: 'Desconto (MZN) *',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: !_submitting,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              validator: (v) {
                final raw = (v ?? '').trim().replaceAll(',', '.');
                if (raw.isEmpty) return 'Campo obrigatório';
                final value = double.tryParse(raw);
                if (value == null) return 'Valor inválido';
                if (value < 0) return 'Desconto não pode ser negativo';
                if (value > maxDiscount) {
                  return 'Desconto não pode exceder ${currency.format(maxDiscount)}';
                }
                final payable = maxDiscount - value;
                if (invoice.paid > payable + 0.001) {
                  return 'Desconto deixa valor líquido inferior ao já pago';
                }
                return null;
              },
            ),
            SizedBox(height: s.md),
            EnterpriseTextFormField(
              controller: _reasonCtrl,
              labelText: 'Motivo (opcional)',
              maxLines: 2,
              minLines: 2,
              enabled: !_submitting,
            ),
          ],
        ),
      ),
      actions: [
        EnterpriseOverlayActions.secondary(
          label: 'Cancelar',
          onPressed: _submitting
              ? null
              : () => closeEnterpriseSideSheet(context, false),
        ),
        EnterpriseOverlayActions.primary(
          label: _submitting ? 'A guardar…' : 'Aplicar desconto',
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}
