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
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../shared/widgets/inputs/enterprise_text_field.dart';
import '../../domain/entities/platform_entities.dart';
import '../providers/platform_providers.dart';
import 'platform_payment_method_cards.dart';

Future<bool> showCreditWalletSideSheet(
  BuildContext context, {
  required String tenantId,
  required String tenantName,
}) async {
  final result = await EnterpriseSideSheet.show<bool>(
    context: context,
    barrierDismissible: false,
    builder: (sheetContext) => CreditWalletSideSheet(
      tenantId: tenantId,
      tenantName: tenantName,
    ),
  );
  return result == true;
}

class CreditWalletSideSheet extends ConsumerStatefulWidget {
  const CreditWalletSideSheet({
    super.key,
    required this.tenantId,
    required this.tenantName,
  });

  final String tenantId;
  final String tenantName;

  @override
  ConsumerState<CreditWalletSideSheet> createState() =>
      _CreditWalletSideSheetState();
}

class _CreditWalletSideSheetState extends ConsumerState<CreditWalletSideSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _method = PlatformPaymentMethods.cash;
  int _months = 1;
  String? _error;
  bool _submitting = false;

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
      setState(() => _error = 'Valor do crédito inválido.');
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
      await ref.read(platformBillingActionsProvider.notifier).creditWallet(
            tenantId: widget.tenantId,
            payload: CreditWalletPayload(
              amount: amount,
              months: _months,
              method: _method,
              reference: reference.isEmpty ? null : reference,
              notes: _notesCtrl.text.trim().isEmpty
                  ? null
                  : _notesCtrl.text.trim(),
            ),
          );
      if (!mounted) return;
      PharmaFeedback.success(context, 'Crédito adicionado com sucesso.');
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
    final async = ref.watch(platformTenantDetailProvider(widget.tenantId));
    final currency = NumberFormat.currency(symbol: 'MT ', decimalDigits: 2);
    final t = context.pharmaTokens;
    final s = context.spacing;

    final body = async.when(
      loading: () => const ModuleLoadingState(itemCount: 3),
      error: (e, _) => ModuleErrorState(
        title: 'Erro',
        message: e.toString(),
        onRetry: () =>
            ref.invalidate(platformTenantDetailProvider(widget.tenantId)),
      ),
      data: (detail) {
        final balance =
            detail.walletBalance ?? detail.subscription?.walletBalance ?? 0;
        final monthly = detail.subscription?.estimatedMonthlyTotal;

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EnterpriseListCard(
                title: 'Tenant',
                subtitle: widget.tenantName,
                leading: Icons.business_rounded,
              ),
              EnterpriseListCard(
                title: 'Saldo Actual',
                subtitle: currency.format(balance),
                leading: Icons.account_balance_wallet_outlined,
              ),
              if (monthly != null) ...[
                SizedBox(height: s.sm),
                Text(
                  'Valor mensal estimado (API): ${currency.format(monthly)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: t.textMuted,
                      ),
                ),
              ],
              SizedBox(height: s.md),
              Text(
                'Cobertura (meses)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SizedBox(height: s.sm),
              PlatformPrepaidMonthsCards(
                value: _months,
                enabled: !_submitting,
                onChanged: (months) => setState(() => _months = months),
              ),
              SizedBox(height: s.md),
              EnterpriseTextFormField(
                controller: _amountCtrl,
                labelText: 'Valor do Crédito *',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                enabled: !_submitting,
                helperText:
                    'Informe o valor devolvido/acordado — sem cálculo local.',
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
              Text(
                'Método',
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
                    ? 'Referência *'
                    : 'Referência',
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
      },
    );

    return EnterpriseFormSideSheet(
      title: const Text('Adicionar Créditos'),
      subtitle: widget.tenantName,
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
          label: _submitting ? 'A processar…' : 'Adicionar Crédito',
          onPressed: _submitting || async.isLoading ? null : _submit,
        ),
      ],
    );
  }
}
