import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_failure.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/widgets/dialogs/enterprise_form_side_sheet.dart';
import '../../../../shared/widgets/dialogs/enterprise_overlay_chrome.dart';
import '../../../../shared/widgets/dialogs/enterprise_overlay_tokens.dart';
import '../../../../shared/widgets/dialogs/enterprise_side_sheet.dart';
import '../../../../shared/widgets/inputs/enterprise_form_grid.dart';
import '../../../../shared/widgets/inputs/enterprise_text_field.dart';
import '../../domain/entities/platform_entities.dart';
import '../providers/platform_providers.dart';

class RegisterTenantFormResult {
  const RegisterTenantFormResult({
    required this.payload,
    this.created,
  });

  final RegisterTenantPayload payload;
  final RegisterTenantResult? created;
}

Future<RegisterTenantFormResult?> showRegisterTenantFormDialog(
  BuildContext context,
) {
  return EnterpriseSideSheet.show<RegisterTenantFormResult>(
    context: context,
    barrierDismissible: false,
    size: EnterpriseOverlaySize.large,
    builder: (sheetContext) => const RegisterTenantFormDialog(),
  );
}

class RegisterTenantFormDialog extends ConsumerStatefulWidget {
  const RegisterTenantFormDialog({super.key});

  @override
  ConsumerState<RegisterTenantFormDialog> createState() =>
      _RegisterTenantFormDialogState();
}

class _RegisterTenantFormDialogState
    extends ConsumerState<RegisterTenantFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tenantNameCtrl = TextEditingController();
  final _tenantEmailCtrl = TextEditingController();
  final _tenantPassCtrl = TextEditingController();
  final _tenantPassConfirmCtrl = TextEditingController();
  final _nuitCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _enderecoCtrl = TextEditingController();
  final List<TextEditingController> _branchCtrls = [
    TextEditingController(),
  ];

  String _planSlug = 'starter';
  String _status = 'trial';
  int _billingPeriodMonths = 1;
  bool _branchNameManual = false;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tenantNameCtrl.addListener(_onTenantNameChanged);
  }

  void _onTenantNameChanged() {
    if (_branchNameManual || _submitting || _branchCtrls.isEmpty) return;
    final next = _tenantNameCtrl.text.trim();
    if (_branchCtrls.first.text != next) {
      _branchCtrls.first.text = next;
    }
  }

  @override
  void dispose() {
    _tenantNameCtrl.removeListener(_onTenantNameChanged);
    _tenantNameCtrl.dispose();
    _tenantEmailCtrl.dispose();
    _tenantPassCtrl.dispose();
    _tenantPassConfirmCtrl.dispose();
    _nuitCtrl.dispose();
    _telefoneCtrl.dispose();
    _enderecoCtrl.dispose();
    for (final c in _branchCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addBranch() {
    setState(() => _branchCtrls.add(TextEditingController()));
  }

  void _removeBranch(int index) {
    if (_branchCtrls.length <= 1) return;
    setState(() {
      _branchCtrls.removeAt(index).dispose();
    });
  }

  RegisterTenantPayload _buildPayload() {
    final tenantName = _tenantNameCtrl.text.trim();
    final branches = _branchCtrls
        .map((c) => c.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    return RegisterTenantPayload(
      tenantName: tenantName,
      ownerEmail: _tenantEmailCtrl.text.trim(),
      ownerPassword: _tenantPassCtrl.text,
      nuit: _nuitCtrl.text.trim().isEmpty ? null : _nuitCtrl.text.trim(),
      telefone: _telefoneCtrl.text.trim().isEmpty ? null : _telefoneCtrl.text.trim(),
      endereco: _enderecoCtrl.text.trim().isEmpty ? null : _enderecoCtrl.text.trim(),
      planSlug: _planSlug,
      status: _status,
      billingPeriodMonths: _billingPeriodMonths,
      branches: branches.isEmpty ? [tenantName] : branches,
    );
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    final payload = _buildPayload();
    setState(() => _submitting = true);

    try {
      final created = await ref
          .read(platformBillingActionsProvider.notifier)
          .registerTenant(payload);
      if (!mounted) return;
      closeEnterpriseSideSheet(
        context,
        RegisterTenantFormResult(payload: payload, created: created),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiFailure
          ? e.message
          : e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _submitting = false;
        _errorMessage = message;
      });
    }
  }

  Widget _sectionTitle(String text) {
    final s = context.spacing;
    return Padding(
      padding: EdgeInsets.only(bottom: s.sm, top: s.sm),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }

  Widget _buildBody() {
    final s = context.spacing;
    final plansAsync = ref.watch(platformPlansProvider);
    final plans = plansAsync.asData?.value.items
            .where((p) => p.active)
            .toList() ??
        const <PlatformPlan>[];

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            Material(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: EdgeInsets.all(s.md),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
            SizedBox(height: s.md),
          ],
          if (_submitting) ...[
            const LinearProgressIndicator(),
            SizedBox(height: s.sm),
            Text(
              'A provisionar cliente (base de dados, migrations e configuração inicial). Isto pode demorar alguns minutos…',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: s.md),
          ],
          _sectionTitle('Dados do Tenant'),
          EnterpriseFormGrid(
            gap: s.md,
            children: [
              EnterpriseFormGridItem(
                fullWidth: true,
                child: EnterpriseTextFormField(
                  controller: _tenantNameCtrl,
                  labelText: 'Nome do Tenant *',
                  enabled: !_submitting,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
                ),
              ),
              EnterpriseFormGridItem(
                fullWidth: true,
                child: EnterpriseTextFormField(
                  controller: _tenantEmailCtrl,
                  labelText: 'Email do Tenant *',
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_submitting,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
                    if (!v.contains('@')) return 'E-mail inválido';
                    return null;
                  },
                ),
              ),
              EnterpriseFormGridItem(
                child: EnterpriseTextFormField(
                  controller: _nuitCtrl,
                  labelText: 'NUIT',
                  keyboardType: TextInputType.number,
                  enabled: !_submitting,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (v.trim().length != 9 || int.tryParse(v.trim()) == null) {
                      return 'NUIT deve ter 9 dígitos';
                    }
                    return null;
                  },
                ),
              ),
              EnterpriseFormGridItem(
                child: EnterpriseTextFormField(
                  controller: _telefoneCtrl,
                  labelText: 'Telefone',
                  keyboardType: TextInputType.phone,
                  enabled: !_submitting,
                ),
              ),
              EnterpriseFormGridItem(
                fullWidth: true,
                child: EnterpriseTextFormField(
                  controller: _enderecoCtrl,
                  labelText: 'Endereço',
                  enabled: !_submitting,
                  maxLines: 2,
                ),
              ),
              EnterpriseFormGridItem(
                child: EnterpriseTextFormField(
                  controller: _tenantPassCtrl,
                  labelText: 'Palavra-passe *',
                  obscureText: true,
                  enabled: !_submitting,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo obrigatório';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
              ),
              EnterpriseFormGridItem(
                child: EnterpriseTextFormField(
                  controller: _tenantPassConfirmCtrl,
                  labelText: 'Confirmar Palavra-passe *',
                  obscureText: true,
                  enabled: !_submitting,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo obrigatório';
                    if (v != _tenantPassCtrl.text) {
                      return 'As palavras-passe não coincidem';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          _sectionTitle('Grupo'),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use — controlled dropdown
            value: plans.any((p) => p.slug == _planSlug)
                ? _planSlug
                : (plans.isNotEmpty ? plans.first.slug : _planSlug),
            decoration: const InputDecoration(labelText: 'Plano *'),
            items: [
              if (plans.isEmpty) ...[
                const DropdownMenuItem(value: 'starter', child: Text('Starter')),
                const DropdownMenuItem(
                  value: 'enterprise',
                  child: Text('Enterprise'),
                ),
              ] else
                ...plans.map(
                  (p) => DropdownMenuItem(
                    value: p.slug,
                    child: Text(p.name),
                  ),
                ),
            ],
            onChanged: _submitting
                ? null
                : (v) => setState(() => _planSlug = v ?? 'starter'),
          ),
          SizedBox(height: s.md),
          _sectionTitle('Subscrição'),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use — controlled dropdown
            value: _status,
            decoration: const InputDecoration(labelText: 'Estado inicial *'),
            items: const [
              DropdownMenuItem(value: 'trial', child: Text('Trial')),
              DropdownMenuItem(value: 'ativo', child: Text('Activo')),
            ],
            onChanged: _submitting
                ? null
                : (v) => setState(() => _status = v ?? 'trial'),
          ),
          SizedBox(height: s.md),
          DropdownButtonFormField<int>(
            // ignore: deprecated_member_use — controlled dropdown
            value: _billingPeriodMonths,
            decoration: const InputDecoration(labelText: 'Período de faturação *'),
            items: [
              for (final months in PlatformPrepaidMonths.options)
                DropdownMenuItem(
                  value: months,
                  child: Text(months == 1 ? '1 mês' : '$months meses'),
                ),
            ],
            onChanged: _submitting
                ? null
                : (v) => setState(() => _billingPeriodMonths = v ?? 1),
          ),
          SizedBox(height: s.sm),
          Row(
            children: [
              Expanded(child: _sectionTitle('Branches')),
              TextButton.icon(
                onPressed: _submitting ? null : _addBranch,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Adicionar Branch'),
              ),
            ],
          ),
          for (var i = 0; i < _branchCtrls.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: EnterpriseTextFormField(
                    controller: _branchCtrls[i],
                    labelText: 'Branch ${i + 1} *',
                    enabled: !_submitting,
                    onChanged: i == 0 ? (_) => _branchNameManual = true : null,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Campo obrigatório'
                        : null,
                  ),
                ),
                if (_branchCtrls.length > 1) ...[
                  SizedBox(width: s.sm),
                  IconButton(
                    tooltip: 'Remover Branch',
                    onPressed: _submitting ? null : () => _removeBranch(i),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              ],
            ),
            if (i < _branchCtrls.length - 1) SizedBox(height: s.md),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EnterpriseFormSideSheet(
      title: const Text('Novo cliente'),
      onClose: _submitting
          ? null
          : () => closeEnterpriseSideSheet(context),
      body: _buildBody(),
      actions: [
        EnterpriseOverlayActions.secondary(
          label: 'Cancelar',
          onPressed: _submitting
              ? null
              : () => closeEnterpriseSideSheet(context),
        ),
        EnterpriseOverlayActions.primary(
          label: _submitting ? 'A criar…' : 'Criar cliente',
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}
