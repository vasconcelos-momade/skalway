import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers/session_access_notifier.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../providers/permission_matrix_provider.dart';

class UserPermissionsPage extends ConsumerWidget {
  const UserPermissionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.spacing;
    final access = ref.watch(sessionAccessProvider);
    final state = ref.watch(permissionMatrixProvider);
    final notifier = ref.read(permissionMatrixProvider.notifier);
    final dash = state.dashboard;

    return EnterpriseModuleHub(
      title: 'Matriz de permissões',
      subtitle: 'Granularidade por módulo e acção.',
      tag: 'Administração',
      actions: [
        if (state.canEdit && state.hasChanges) ...[
          OutlinedButton(
            onPressed: state.isBusy ? null : notifier.discardChanges,
            child: const Text('Descartar'),
          ),
          FilledButton(
            onPressed: state.isBusy
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
        ],
        OutlinedButton.icon(
          onPressed: state.isBusy
              ? null
              : () => notifier.load(role: state.selectedRole),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
      ],
      filters: Wrap(
        spacing: s.sm,
        runSpacing: s.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DropdownButton<String?>(
            value: state.selectedRole,
            hint: const Text('Filtrar por perfil'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos os perfis')),
              for (final g in dash.grantsByRole)
                DropdownMenuItem(
                  value: g.role,
                  child: Text('${g.role} (${g.count})'),
                ),
            ],
            onChanged: state.isBusy ? null : notifier.setRoleFilter,
          ),
          if (state.canEdit)
            Text(
              'Modo edição — alterações afectam o perfil ${state.selectedRole}',
              style: Theme.of(context).textTheme.erpCaption.copyWith(
                    color: context.pharmaTokens.brandBlue,
                  ),
            ),
        ],
      ),
      kpis: [
        EnterpriseStatCard(
          title: 'Grants por perfil',
          value: '${dash.totalRoleGrants}',
          icon: Icons.vpn_key_outlined,
          accent: StatCardAccent.info,
        ),
        EnterpriseStatCard(
          title: 'Overrides',
          value: '${dash.totalUserOverrides}',
          icon: Icons.tune,
          accent: StatCardAccent.warning,
        ),
        EnterpriseStatCard(
          title: 'Módulos',
          value: '${state.rows.length}',
          icon: Icons.grid_view_outlined,
          accent: StatCardAccent.neutral,
        ),
      ],
      child: !access.isResolved
          ? const ModuleLoadingState()
          : access.canAccessAdministration
          ? _buildBody(context, state, notifier)
          : ModuleErrorState(
              title: 'Sem acesso à administração',
              message:
                  'A sessão atual não possui a permissão UTILIZADORES:VIEW.',
              onRetry: () => ref.read(sessionAccessProvider.notifier).refresh(),
              icon: Icons.lock_outline,
            ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PermissionMatrixState state,
    PermissionMatrixController notifier,
  ) {
    if (state.viewState == PermissionMatrixViewState.loading) {
      return const ModuleLoadingState();
    }
    if (state.viewState == PermissionMatrixViewState.error) {
      return ModuleErrorState(
        title: 'Falha ao carregar permissões',
        message: state.errorMessage ?? 'Erro desconhecido',
        onRetry: () => notifier.load(role: state.selectedRole),
        icon: Icons.vpn_key_outlined,
      );
    }
    if (state.rows.isEmpty) {
      return const ModuleEmptyState(
        title: 'Matriz vazia',
        subtitle: 'Não existem permissões configuradas.',
      );
    }

    final t = context.pharmaTokens;
    final editing = state.canEdit;

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
        final moduleMap = state.editableMatrix[row.module];
        return DataRow(
          cells: [
            DataCell(Text(
              row.module,
              style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.textPrimary),
            )),
            for (final action in permissionMatrixActions)
              DataCell(_actionCell(
                context,
                editing: editing,
                enabled: editing
                    ? (moduleMap?[action] ?? false)
                    : row.actions[action],
                onToggle: editing
                    ? () => notifier.togglePermission(row.module, action)
                    : null,
                busy: state.isBusy,
              )),
          ],
        );
      },
    );
  }

  Widget _actionCell(
    BuildContext context, {
    required bool editing,
    required dynamic enabled,
    required VoidCallback? onToggle,
    required bool busy,
  }) {
    final t = context.pharmaTokens;

    if (editing) {
      return Checkbox(
        value: enabled == true,
        onChanged: busy ? null : (_) => onToggle?.call(),
      );
    }

    if (enabled is List) {
      return Text(
        '${enabled.length} perfis',
        style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.brandBlue),
      );
    }

    if (enabled == true) {
      return Icon(Icons.check_circle, color: t.brandGreen, size: 20);
    }

    return Icon(Icons.remove, color: t.textMuted, size: 18);
  }

  Future<void> _save(
    BuildContext context,
    PermissionMatrixController notifier,
  ) async {
    try {
      await notifier.saveRolePermissions();
      if (context.mounted) {
        PharmaFeedback.success(context, 'Permissões actualizadas');
      }
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    } catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.toString());
    }
  }
}
