import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/extensions.dart';
import '../../../../shared/widgets/dialogs/enterprise_form_side_sheet.dart';
import '../../../../shared/widgets/dialogs/enterprise_overlay_chrome.dart';
import '../../../../shared/widgets/dialogs/enterprise_side_sheet.dart';
import '../../../../shared/widgets/inputs/enterprise_select_field.dart';
import '../../../../shared/widgets/inputs/enterprise_text_field.dart';
import '../../domain/entities/platform_entities.dart';

Future<PlatformPlanPayload?> showPlanFormSideSheet(
  BuildContext context, {
  PlatformPlan? plan,
}) {
  return EnterpriseSideSheet.show<PlatformPlanPayload>(
    context: context,
    barrierDismissible: false,
    builder: (sheetContext) => PlanFormSideSheet(plan: plan),
  );
}

class PlanFormSideSheet extends StatefulWidget {
  const PlanFormSideSheet({super.key, this.plan});

  final PlatformPlan? plan;

  bool get isEditing => plan != null;

  @override
  State<PlanFormSideSheet> createState() => _PlanFormSideSheetState();
}

class _PlanFormSideSheetState extends State<PlanFormSideSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _slug;
  late final TextEditingController _monthlyPrice;
  late final TextEditingController _includedBranches;
  late final TextEditingController _extraBranchPrice;
  late final TextEditingController _trialDays;
  late int _billingInterval;
  late bool _active;
  late bool _isEnterprise;

  static const _intervals = <int>[1, 3, 6, 12];

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _name = TextEditingController(text: p?.name ?? '');
    _slug = TextEditingController(text: p?.slug ?? '');
    _monthlyPrice = TextEditingController(
      text: p == null ? '' : p.monthlyPrice.toStringAsFixed(2),
    );
    _includedBranches = TextEditingController(
      text: '${p?.includedBranches ?? 1}',
    );
    _extraBranchPrice = TextEditingController(
      text: p == null ? '0' : p.extraBranchPrice.toStringAsFixed(2),
    );
    _trialDays = TextEditingController(text: '${p?.trialDays ?? 14}');
    _billingInterval = p?.billingIntervalMonths ?? 1;
    if (!_intervals.contains(_billingInterval)) {
      _billingInterval = 1;
    }
    _active = p?.active ?? true;
    _isEnterprise = p?.isEnterprise ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _monthlyPrice.dispose();
    _includedBranches.dispose();
    _extraBranchPrice.dispose();
    _trialDays.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    closeEnterpriseSideSheet(
      context,
      PlatformPlanPayload(
        name: _name.text.trim(),
        slug: _slug.text.trim().toLowerCase(),
        monthlyPrice:
            double.parse(_monthlyPrice.text.replaceAll(',', '.')),
        includedBranches: int.parse(_includedBranches.text.trim()),
        extraBranchPrice:
            double.parse(_extraBranchPrice.text.replaceAll(',', '.')),
        billingIntervalMonths: _billingInterval,
        trialDays: int.parse(_trialDays.text.trim()),
        active: _active,
        isEnterprise: _isEnterprise,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    final body = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EnterpriseTextFormField(
            controller: _name,
            labelText: 'Nome *',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
          ),
          SizedBox(height: s.md),
          EnterpriseTextFormField(
            controller: _slug,
            labelText: 'Slug *',
            helperText: 'a-z, 0-9, _ ou -',
            textCapitalization: TextCapitalization.none,
            validator: (v) {
              final value = (v ?? '').trim().toLowerCase();
              if (value.length < 2) return 'Mínimo 2 caracteres';
              if (!RegExp(r'^[a-z0-9_-]+$').hasMatch(value)) {
                return 'Slug inválido';
              }
              return null;
            },
          ),
          SizedBox(height: s.md),
          EnterpriseTextFormField(
            controller: _monthlyPrice,
            labelText: 'Preço Mensal *',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            validator: (v) {
              final n = double.tryParse((v ?? '').replaceAll(',', '.'));
              if (n == null || n < 0) return 'Valor inválido';
              return null;
            },
          ),
          SizedBox(height: s.md),
          EnterpriseTextFormField(
            controller: _includedBranches,
            labelText: 'Filiais Incluídas *',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              final n = int.tryParse((v ?? '').trim());
              if (n == null || n < 1) return 'Mínimo 1';
              return null;
            },
          ),
          SizedBox(height: s.md),
          EnterpriseTextFormField(
            controller: _extraBranchPrice,
            labelText: 'Preço por Filial Extra *',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            validator: (v) {
              final n = double.tryParse((v ?? '').replaceAll(',', '.'));
              if (n == null || n < 0) return 'Valor inválido';
              return null;
            },
          ),
          SizedBox(height: s.md),
          EnterpriseTextFormField(
            controller: _trialDays,
            labelText: 'Dias de Trial *',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              final n = int.tryParse((v ?? '').trim());
              if (n == null || n < 0 || n > 365) return '0 a 365';
              return null;
            },
          ),
          SizedBox(height: s.md),
          EnterpriseSelectField<int>(
            label: 'Intervalo de Facturação',
            value: _billingInterval,
            options: [
              for (final months in _intervals)
                EnterpriseSelectOption(
                  value: months,
                  label: months == 1 ? '1 mês' : '$months meses',
                ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _billingInterval = v);
            },
          ),
          SizedBox(height: s.md),
          EnterpriseFormSwitch(
            label: 'Activo',
            value: _active,
            onChanged: (v) => setState(() => _active = v),
          ),
          EnterpriseFormSwitch(
            label: 'Enterprise',
            value: _isEnterprise,
            onChanged: (v) => setState(() => _isEnterprise = v),
          ),
        ],
      ),
    );

    return EnterpriseFormSideSheet(
      title: Text(widget.isEditing ? 'Editar Plano' : 'Criar Plano'),
      onClose: () => closeEnterpriseSideSheet(context),
      body: body,
      actions: [
        EnterpriseOverlayActions.secondary(
          label: 'Cancelar',
          onPressed: () => closeEnterpriseSideSheet(context),
        ),
        EnterpriseOverlayActions.primary(
          label: widget.isEditing ? 'Guardar' : 'Criar',
          onPressed: _submit,
        ),
      ],
    );
  }
}
