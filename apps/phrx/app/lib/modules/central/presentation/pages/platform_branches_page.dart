import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/refresh/page_refresh.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/menus/enterprise_actions_menu_button.dart';
import '../../../../shared/widgets/menus/enterprise_dropdown_menu.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../domain/entities/platform_entities.dart';
import '../providers/platform_providers.dart';

class PlatformBranchesPage extends ConsumerWidget {
  const PlatformBranchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(platformBranchesProvider);

    return PageRefreshBinder(
      onRefresh: () async => ref.invalidate(platformBranchesProvider),
      child: EnterpriseModuleHub(
        title: 'Branches / Filiais',
        subtitle: 'Lista global de filiais de todos os tenants.',
        tag: 'Plataforma',
        child: async.when(
          loading: () => const ModuleLoadingState(),
          error: (e, _) => ModuleErrorState(
            title: 'Erro ao carregar filiais',
            message: e.toString(),
            onRetry: () => ref.invalidate(platformBranchesProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const ModuleEmptyState(title: 'Nenhuma filial encontrada.');
            }
            return EnterpriseDataTable(
              columns: const [
                DataColumn(label: Text('Tenant')),
                DataColumn(label: Text('Branch / Filial')),
                DataColumn(label: Text('Estado')),
                DataColumn(label: Text('Acções')),
              ],
              rowCount: items.length,
              rowBuilder: (context, index) {
                final item = items[index];
                final branch = item.branch;
                return DataRow(
                  cells: [
                    DataCell(
                      _BranchTenantCell(
                        title: item.tenantName,
                        subtitle: item.companyName,
                      ),
                    ),
                    DataCell(
                      _BranchNameCell(
                        name: branch.name,
                        code: branch.code,
                        isHeadOffice: branch.isHeadOffice,
                      ),
                    ),
                    DataCell(
                      EnterpriseStatusChip(
                        label: branch.active ? 'Activa' : 'Inactiva',
                        color: branch.active
                            ? context.pharmaTokens.posSuccess
                            : context.pharmaTokens.posDanger,
                      ),
                    ),
                    DataCell(
                      _BranchActionsMenu(
                        item: item,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _BranchTenantCell extends StatelessWidget {
  const _BranchTenantCell({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.pharmaTokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(color: tokens.textMuted),
        ),
      ],
    );
  }
}

class _BranchNameCell extends StatelessWidget {
  const _BranchNameCell({
    required this.name,
    required this.code,
    required this.isHeadOffice,
  });

  final String name;
  final String code;
  final bool isHeadOffice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.pharmaTokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ),
            if (isHeadOffice) ...[
              const SizedBox(width: 8),
              EnterpriseStatusChip(
                label: 'Matriz',
                color: tokens.posInfo,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          code,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(color: tokens.textMuted),
        ),
      ],
    );
  }
}

enum _BranchAction { enable, disable }

class _BranchActionsMenu extends ConsumerWidget {
  const _BranchActionsMenu({required this.item});

  final PlatformBranchListItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branch = item.branch;
    final busy = ref.watch(platformBillingActionsProvider);
    final canDisable = branch.active && !branch.isHeadOffice;
    final canEnable = !branch.active;

    return EnterpriseActionsMenuButton<_BranchAction>(
      tooltip: 'Acções da filial',
      items: [
        EnterpriseDropdownItem<_BranchAction>(
          value: _BranchAction.enable,
          label: 'Activar branch',
          icon: Icons.check_circle_outline_rounded,
          enabled: canEnable && !busy,
        ),
        EnterpriseDropdownItem<_BranchAction>(
          value: _BranchAction.disable,
          label: 'Desactivar branch',
          icon: Icons.block_rounded,
          enabled: canDisable && !busy,
          destructive: true,
        ),
      ],
      onSelected: (action) => _onSelected(context, ref, action),
    );
  }

  Future<void> _onSelected(
    BuildContext context,
    WidgetRef ref,
    _BranchAction action,
  ) async {
    final branch = item.branch;
    switch (action) {
      case _BranchAction.enable:
        final confirmed = await PharmaFeedback.confirm(
          context: context,
          title: 'Activar filial',
          message:
              'A filial "${branch.name}" será activada e poderá ser cobrada '
              'na próxima renovação.',
          confirmText: 'Activar',
        );
        if (!confirmed || !context.mounted) return;
        try {
          await ref.read(platformBillingActionsProvider.notifier).activateBranch(
                tenantId: item.tenantId,
                branchId: branch.id,
                reason: 'Activação via lista global de filiais',
              );
          if (!context.mounted) return;
          PharmaFeedback.success(context, 'Filial activada.');
        } catch (e) {
          if (!context.mounted) return;
          PharmaFeedback.error(context, e.toString());
        }
      case _BranchAction.disable:
        final confirmed = await PharmaFeedback.confirm(
          context: context,
          title: 'Desactivar filial',
          message:
              'A filial "${branch.name}" será desactivada imediatamente e '
              'deixará de ser cobrada na próxima renovação.',
          confirmText: 'Desactivar',
          destructive: true,
        );
        if (!confirmed || !context.mounted) return;
        try {
          await ref
              .read(platformBillingActionsProvider.notifier)
              .deactivateBranch(
                tenantId: item.tenantId,
                branchId: branch.id,
                reason: 'Desactivação via lista global de filiais',
              );
          if (!context.mounted) return;
          PharmaFeedback.success(context, 'Filial desactivada.');
        } catch (e) {
          if (!context.mounted) return;
          PharmaFeedback.error(context, e.toString());
        }
    }
  }
}
