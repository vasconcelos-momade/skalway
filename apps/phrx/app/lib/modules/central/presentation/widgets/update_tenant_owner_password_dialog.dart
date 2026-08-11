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
import '../providers/platform_providers.dart';

Future<bool?> showUpdateOwnerPasswordDialog(
  BuildContext context, {
  required String tenantId,
  required String tenantName,
}) {
  return EnterpriseSideSheet.show<bool>(
    context: context,
    barrierDismissible: false,
    size: EnterpriseOverlaySize.small,
    builder: (sheetContext) => UpdateOwnerPasswordSideSheet(
      tenantId: tenantId,
      tenantName: tenantName,
    ),
  );
}

class UpdateOwnerPasswordSideSheet extends ConsumerStatefulWidget {
  const UpdateOwnerPasswordSideSheet({
    super.key,
    required this.tenantId,
    required this.tenantName,
  });

  final String tenantId;
  final String tenantName;

  @override
  ConsumerState<UpdateOwnerPasswordSideSheet> createState() =>
      _UpdateOwnerPasswordSideSheetState();
}

class _UpdateOwnerPasswordSideSheetState
    extends ConsumerState<UpdateOwnerPasswordSideSheet> {
  final _formKey = GlobalKey<FormState>();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(platformBillingActionsProvider.notifier)
          .updateOwnerPassword(widget.tenantId, _newPassCtrl.text);
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
      title: Text('Alterar senha — ${widget.tenantName}'),
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
                    controller: _newPassCtrl,
                    labelText: 'Nova palavra-passe *',
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
                  fullWidth: true,
                  child: EnterpriseTextFormField(
                    controller: _confirmPassCtrl,
                    labelText: 'Confirmar palavra-passe *',
                    obscureText: true,
                    enabled: !_submitting,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo obrigatório';
                      if (v != _newPassCtrl.text) return 'As palavras-passe não coincidem';
                      return null;
                    },
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
          label: _submitting ? 'A actualizar…' : 'Actualizar senha',
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}
