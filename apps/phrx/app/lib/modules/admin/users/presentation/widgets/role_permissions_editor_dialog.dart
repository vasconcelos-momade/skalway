import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../providers/permission_matrix_provider.dart';

Future<bool?> showRolePermissionsEditorDialog(
  BuildContext context, {
  required String role,
}) {
  return AdaptiveNavigator.openEmbeddedForm<bool>(
    context: context,
    title: Text('Permissões — $role'),
    routeSettings: RouteSettings(name: '/perfis/$role/permissoes'),
    sideSheetWidth: 720,
    formBuilder: (ctx, {required embedded}) =>
        RolePermissionsEditorDialog(role: role, embedded: embedded),
  );
}

class RolePermissionsEditorDialog extends ConsumerStatefulWidget {
  const RolePermissionsEditorDialog({
    super.key,
    required this.role,
    this.embedded = false,
  });

  final String role;
  final bool embedded;

  @override
  ConsumerState<RolePermissionsEditorDialog> createState() =>
      _RolePermissionsEditorDialogState();
}

class _RolePermissionsEditorDialogState
    extends ConsumerState<RolePermissionsEditorDialog> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(permissionMatrixProvider.notifier).load(role: widget.role),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(permissionMatrixProvider);
    final notifier = ref.read(permissionMatrixProvider.notifier);

    final content = SizedBox(
      height: widget.embedded ? 480 : 480,
      child: _buildContent(context, state, notifier),
    );

    final actions = [
      TextButton(
        onPressed: state.isBusy ? null : () => AdaptiveNavigator.cancel(context),
        child: const Text('Fechar'),
      ),
      if (state.canEdit && state.hasChanges)
        TextButton(
          onPressed: state.isBusy ? null : notifier.discardChanges,
          child: const Text('Descartar'),
        ),
      FilledButton(
        onPressed: !state.canEdit || state.isBusy || !state.hasChanges
            ? null
            : () => _save(context, notifier),
        child: state.viewState == PermissionMatrixViewState.saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Guardar'),
      ),
    ];

    if (widget.embedded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          content,
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: actions,
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text('Permissões — ${widget.role}'),
      content: content,
      actions: actions,
    );
  }

  Widget _buildContent(
    BuildContext context,
    PermissionMatrixState state,
    PermissionMatrixController notifier,
  ) {
    if (state.viewState == PermissionMatrixViewState.loading) {
      return const ModuleLoadingState();
    }
    if (state.viewState == PermissionMatrixViewState.error) {
      return ModuleErrorState(
        title: 'Falha ao carregar',
        message: state.errorMessage ?? 'Erro desconhecido',
        onRetry: () => notifier.load(role: widget.role),
        icon: Icons.vpn_key_outlined,
      );
    }
    if (state.rows.isEmpty) {
      return const ModuleEmptyState(
        title: 'Matriz vazia',
        subtitle: 'Não existem módulos configurados.',
      );
    }

    final t = context.pharmaTokens;

    return EnterpriseDataTable(
      columns: [
        DataColumn(
          label: Text(
            'MÓDULO',
            style: Theme.of(context).textTheme.erpOverline.copyWith(color: t.textMuted),
          ),
        ),
        for (final action in permissionMatrixActions)
          DataColumn(
            label: Text(
              action,
              style: Theme.of(context).textTheme.erpOverline.copyWith(color: t.textMuted),
            ),
          ),
      ],
      rowCount: state.rows.length,
      rowBuilder: (context, index) {
        final row = state.rows[index];
        final moduleMap = state.editableMatrix[row.module] ?? {};
        return DataRow(
          cells: [
            DataCell(Text(
              row.module,
              style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.textPrimary),
            )),
            for (final action in permissionMatrixActions)
              DataCell(
                Checkbox(
                  value: moduleMap[action] ?? false,
                  onChanged: state.isBusy
                      ? null
                      : (_) => notifier.togglePermission(row.module, action),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _save(
    BuildContext context,
    PermissionMatrixController notifier,
  ) async {
    try {
      await notifier.saveRolePermissions();
      if (context.mounted) {
        PharmaFeedback.success(context, 'Permissões actualizadas');
        AdaptiveNavigator.complete(context, true);
      }
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    } catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.toString());
    }
  }
}
