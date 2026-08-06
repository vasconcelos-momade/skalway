import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_failure.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/widgets/dialogs/enterprise_form_side_sheet.dart';
import '../../../../shared/widgets/dialogs/enterprise_overlay_chrome.dart';
import '../../../../shared/widgets/dialogs/enterprise_side_sheet.dart';
import '../../../../shared/widgets/inputs/enterprise_text_field.dart';
import '../../domain/entities/platform_entities.dart';
import '../providers/platform_providers.dart';

Future<PlatformBranch?> showCreateBranchFormDialog(
  BuildContext context, {
  required String tenantId,
}) {
  return EnterpriseSideSheet.show<PlatformBranch>(
    context: context,
    barrierDismissible: false,
    builder: (sheetContext) => CreateBranchFormDialog(tenantId: tenantId),
  );
}

class CreateBranchFormDialog extends ConsumerStatefulWidget {
  const CreateBranchFormDialog({
    super.key,
    required this.tenantId,
  });

  final String tenantId;

  @override
  ConsumerState<CreateBranchFormDialog> createState() =>
      _CreateBranchFormDialogState();
}

class _CreateBranchFormDialogState
    extends ConsumerState<CreateBranchFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final branch = await ref
          .read(platformBillingActionsProvider.notifier)
          .createBranch(
            tenantId: widget.tenantId,
            name: _nameCtrl.text.trim(),
          );
      if (!mounted) return;
      closeEnterpriseSideSheet(context, branch);
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiFailure ? e.message : e.toString();
      setState(() {
        _submitting = false;
        _errorMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    return EnterpriseFormSideSheet(
      title: const Text('Nova filial'),
      onClose: _submitting
          ? null
          : () => closeEnterpriseSideSheet(context),
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
              SizedBox(height: s.md),
            ],
            Text(
              'Cria uma filial para este tenant. '
              'O código é gerado automaticamente. '
              'A criação nunca é bloqueada pelo limite do plano — '
              'filiais extras entram na próxima factura.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: s.md),
            EnterpriseTextFormField(
              controller: _nameCtrl,
              enabled: !_submitting,
              labelText: 'Nome *',
              hintText: 'ex: Filial Beira',
              validator: (v) {
                if ((v ?? '').trim().isEmpty) return 'Nome obrigatório';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        EnterpriseOverlayActions.secondary(
          label: 'Cancelar',
          onPressed: _submitting
              ? null
              : () => closeEnterpriseSideSheet(context),
        ),
        EnterpriseOverlayActions.primary(
          label: _submitting ? 'A criar…' : 'Criar filial',
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}
