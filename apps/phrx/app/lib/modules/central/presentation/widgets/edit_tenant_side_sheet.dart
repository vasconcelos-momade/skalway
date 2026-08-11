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

Future<bool?> showEditTenantSideSheet(
  BuildContext context, {
  required PlatformTenantSummary tenant,
}) {
  return EnterpriseSideSheet.show<bool>(
    context: context,
    barrierDismissible: false,
    size: EnterpriseOverlaySize.medium,
    builder: (sheetContext) => EditTenantSideSheet(tenant: tenant),
  );
}

class EditTenantSideSheet extends ConsumerStatefulWidget {
  const EditTenantSideSheet({super.key, required this.tenant});

  final PlatformTenantSummary tenant;

  @override
  ConsumerState<EditTenantSideSheet> createState() => _EditTenantSideSheetState();
}

class _EditTenantSideSheetState extends ConsumerState<EditTenantSideSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _nuitCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _telefoneCtrl;
  late final TextEditingController _enderecoCtrl;

  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.tenant.tenantName);
    _nuitCtrl = TextEditingController(text: widget.tenant.nuit ?? '');
    _emailCtrl = TextEditingController(text: widget.tenant.email ?? '');
    _telefoneCtrl = TextEditingController(text: widget.tenant.telefone ?? '');
    _enderecoCtrl = TextEditingController(text: widget.tenant.endereco ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nuitCtrl.dispose();
    _emailCtrl.dispose();
    _telefoneCtrl.dispose();
    _enderecoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final payload = UpdateTenantPayload(
        tenantName: _nameCtrl.text.trim(),
        nuit: _nuitCtrl.text.trim().isEmpty ? null : _nuitCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        telefone: _telefoneCtrl.text.trim().isEmpty ? null : _telefoneCtrl.text.trim(),
        endereco: _enderecoCtrl.text.trim().isEmpty ? null : _enderecoCtrl.text.trim(),
      );
      await ref
          .read(platformBillingActionsProvider.notifier)
          .updateTenant(widget.tenant.id, payload);
      if (!mounted) return;
      closeEnterpriseSideSheet(context, true);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiFailure ? e.message : e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _submitting = false;
        _errorMessage = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    return EnterpriseFormSideSheet(
      title: const Text('Editar Tenant'),
      onClose: _submitting ? null : () => closeEnterpriseSideSheet(context),
      body: Form(
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
                    style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                ),
              ),
              SizedBox(height: s.md),
            ],
            if (_submitting) ...[
              const LinearProgressIndicator(),
              SizedBox(height: s.sm),
            ],
            EnterpriseFormGrid(
              gap: s.md,
              children: [
                EnterpriseFormGridItem(
                  fullWidth: true,
                  child: EnterpriseTextFormField(
                    controller: _nameCtrl,
                    labelText: 'Nome *',
                    enabled: !_submitting,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
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
                    controller: _emailCtrl,
                    labelText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_submitting,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      if (!v.contains('@')) return 'E-mail inválido';
                      return null;
                    },
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
              ],
            ),
          ],
        ),
      ),
      actions: [
        EnterpriseOverlayActions.secondary(
          label: 'Cancelar',
          onPressed: _submitting ? null : () => closeEnterpriseSideSheet(context),
        ),
        EnterpriseOverlayActions.primary(
          label: _submitting ? 'A guardar…' : 'Guardar',
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}
