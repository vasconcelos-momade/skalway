import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_failure.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../shared/widgets/dialogs/enterprise_overlay_tokens.dart';
import '../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../domain/entities/platform_entities.dart';
import '../providers/platform_providers.dart';

Future<PlatformBranch?> showCreateBranchFormDialog(
  BuildContext context, {
  required String tenantId,
}) {
  return AdaptiveNavigator.openEmbeddedForm<PlatformBranch>(
    context: context,
    title: const Text('Nova filial'),
    routeSettings: RouteSettings(name: '/platform/tenants/$tenantId/branches/nova'),
    size: EnterpriseOverlaySize.medium,
    barrierDismissible: false,
    forceSideSheet: true,
    formBuilder: (ctx, {required embedded}) => CreateBranchFormDialog(
      tenantId: tenantId,
      embedded: embedded,
    ),
  );
}

class CreateBranchFormDialog extends ConsumerStatefulWidget {
  const CreateBranchFormDialog({
    super.key,
    required this.tenantId,
    this.embedded = false,
  });

  final String tenantId;
  final bool embedded;

  @override
  ConsumerState<CreateBranchFormDialog> createState() =>
      _CreateBranchFormDialogState();
}

class _CreateBranchFormDialogState
    extends ConsumerState<CreateBranchFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
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
      AdaptiveNavigator.complete(context, branch);
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiFailure ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cria uma filial para este tenant. '
            'O código é gerado automaticamente. '
            'A criação nunca é bloqueada pelo limite do plano — '
            'filiais extras entram na próxima factura.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _nameCtrl,
            enabled: !_submitting,
            decoration: const InputDecoration(
              labelText: 'Nome *',
              hintText: 'ex: Filial Beira',
            ),
            validator: (v) {
              if ((v ?? '').trim().isEmpty) return 'Nome obrigatório';
              return null;
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _actions() => [
        TextButton(
          onPressed:
              _submitting ? null : () => AdaptiveNavigator.cancel(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Criar filial'),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBody(),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: _actions()),
        ],
      );
    }

    return PharmaResponsiveDialog(
      title: const Text('Nova filial'),
      content: _buildBody(),
      actions: _actions(),
    );
  }
}
