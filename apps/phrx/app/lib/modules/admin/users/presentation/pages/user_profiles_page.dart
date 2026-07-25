import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers/session_access_notifier.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../domain/entities/user_entities.dart';
import '../providers/role_list_provider.dart';
import '../widgets/role_permissions_editor_dialog.dart';

class UserProfilesPage extends ConsumerWidget {
  const UserProfilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(sessionAccessProvider);
    final state = ref.watch(roleListProvider);
    final notifier = ref.read(roleListProvider.notifier);
    final totalUsers = state.roles.fold<int>(0, (sum, r) => sum + r.userCount);

    return EnterpriseModuleHub(
      title: 'Perfis de acesso',
      subtitle: 'Conjuntos de permissões reutilizáveis por unidade.',
      tag: 'Administração',
      actions: [
        OutlinedButton.icon(
          onPressed: state.isBusy ? null : notifier.load,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
      ],
      kpis: [
        EnterpriseStatCard(
          title: 'Perfis',
          value: '${state.roles.length}',
          icon: Icons.badge_outlined,
          accent: StatCardAccent.info,
        ),
        EnterpriseStatCard(
          title: 'Utilizadores',
          value: '$totalUsers',
          icon: Icons.people_outline,
          accent: StatCardAccent.positive,
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
    RoleListState state,
    RoleListController notifier,
  ) {
    if (state.viewState == RoleListViewState.loading) {
      return const ModuleLoadingState();
    }
    if (state.viewState == RoleListViewState.error) {
      return ModuleErrorState(
        title: 'Falha ao carregar perfis',
        message: state.errorMessage ?? 'Erro desconhecido',
        onRetry: notifier.load,
        icon: Icons.badge_outlined,
      );
    }

    final t = context.pharmaTokens;
    final s = context.spacing;
    final selected = state.selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: selected == null ? 1 : 2,
          child: EnterpriseDataTable(
            columns: [
              for (final label in ['Perfil', 'Descrição', 'Utilizadores', ''])
                DataColumn(
                  label: Text(
                    label.toUpperCase(),
                    style: Theme.of(context).textTheme.erpOverline.copyWith(color: t.textMuted),
                  ),
                ),
            ],
            rowCount: state.roles.length,
            rowBuilder: (context, index) {
              final role = state.roles[index];
              final isSelected = selected?.role == role.role;
              return DataRow(
                selected: isSelected,
                onSelectChanged: (_) => notifier.selectRole(role.role),
                cells: [
                  DataCell(Text(
                    _roleLabel(role.role),
                    style: Theme.of(context).textTheme.erpCardTitle.copyWith(color: t.textPrimary),
                  )),
                  DataCell(Text(
                    role.description ?? '—',
                    style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textSecondary),
                  )),
                  DataCell(Text(
                    '${role.userCount}',
                    style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.brandBlue),
                  )),
                  DataCell(Icon(
                    isSelected ? Icons.expand_less : Icons.chevron_right,
                    color: t.textMuted,
                    size: 20,
                  )),
                ],
              );
            },
          ),
        ),
        if (selected != null) ...[
          SizedBox(height: s.md),
          Expanded(
            child: _RoleDetailPanel(
              detail: selected,
              onClose: notifier.clearSelection,
              onPermissionsUpdated: () => notifier.selectRole(selected.role),
            ),
          ),
        ],
      ],
    );
  }

  String _roleLabel(String role) => switch (role) {
        'ADMIN' => 'Administrador',
        'GERENTE' => 'Gestor',
        'FARMACEUTICO' => 'Farmacêutico',
        'DIRETOR_TECNICO' => 'Director técnico',
        'CAIXA' => 'Caixa PDV',
        _ => role,
      };
}

class _RoleDetailPanel extends StatelessWidget {
  const _RoleDetailPanel({
    required this.detail,
    required this.onClose,
    this.onPermissionsUpdated,
  });

  final RoleDetail detail;
  final VoidCallback onClose;
  final VoidCallback? onPermissionsUpdated;

  Future<void> _openPermissionsEditor(BuildContext context) async {
    final updated = await showRolePermissionsEditorDialog(
      context,
      role: detail.role,
    );
    if (updated == true && context.mounted) {
      onPermissionsUpdated?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Material(
      color: t.card,
      borderRadius: BorderRadius.circular(t.radiusXl),
      child: Padding(
        padding: EdgeInsets.all(s.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${detail.role} — ${detail.permissions.length} permissões',
                    style: Theme.of(context).textTheme.erpCardTitle.copyWith(color: t.textPrimary),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _openPermissionsEditor(context),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar permissões'),
                ),
                IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
              ],
            ),
            SizedBox(height: s.sm),
            Expanded(
              child: ListView(
                children: [
                  Text(
                    'Utilizadores (${detail.users.length})',
                    style: Theme.of(context).textTheme.erpCaption.copyWith(color: t.textMuted),
                  ),
                  for (final u in detail.users)
                    ListTile(
                      dense: true,
                      title: Text(
                        u.name,
                        style: Theme.of(context).textTheme.erpBody.copyWith(color: t.textPrimary),
                      ),
                      subtitle: Text(
                        u.email ?? '—',
                        style: Theme.of(context).textTheme.erpCaption.copyWith(color: t.textMuted),
                      ),
                      trailing: Icon(
                        u.active ? Icons.check_circle : Icons.cancel,
                        color: u.active ? t.brandGreen : t.posDanger,
                        size: 18,
                      ),
                    ),
                  Divider(color: t.border.withValues(alpha: 0.35)),
                  Text(
                    'Permissões',
                    style: Theme.of(context).textTheme.erpCaption.copyWith(color: t.textMuted),
                  ),
                  Wrap(
                    spacing: s.sm,
                    runSpacing: s.sm,
                    children: [
                      for (final p in detail.permissions)
                        Chip(
                          label: Text(
                            '${p.module}.${p.action}',
                            style: Theme.of(context).textTheme.erpCaption,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
