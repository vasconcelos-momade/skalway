import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../shared/widgets/dialogs/enterprise_overlays.dart';
import '../../../../shared/widgets/menus/enterprise_actions_menu_button.dart';
import '../../../../shared/widgets/menus/enterprise_dropdown_menu.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/inputs/enterprise_search_field.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../domain/entities/platform_entities.dart';
import '../providers/platform_providers.dart';
import '../widgets/create_branch_form_dialog.dart';
import '../widgets/register_tenant_form_dialog.dart';
import '../../../../shared/refresh/page_refresh.dart';

class PlatformTenantsPage extends ConsumerStatefulWidget {
  const PlatformTenantsPage({super.key});

  @override
  ConsumerState<PlatformTenantsPage> createState() =>
      _PlatformTenantsPageState();
}

class _PlatformTenantsPageState extends ConsumerState<PlatformTenantsPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(platformTenantsProvider);
    final notifier = ref.read(platformTenantsProvider.notifier);
    final currency = NumberFormat.currency(symbol: 'MT ', decimalDigits: 0);
    final dateFmt = DateFormat('dd/MM/yyyy');

    return PageRefreshBinder(
      onRefresh: () => notifier.refresh(),
      child: EnterpriseModuleHub(
        title: 'Subscrição de tenantes',
        subtitle: 'Gestão das subscrições, filiais e histórico operacional dos tenants.',
        tag: 'Plataforma',
        actions: [
          FilledButton.icon(
            onPressed: () => _createTenant(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Novo tenant'),
          ),
        ],
        filters: EnterpriseSearchField(
          controller: _searchCtrl,
          hintText: 'Pesquisar tenant ou empresa…',
          onChanged: notifier.setSearch,
        ),
        child: async.when(
          loading: () => const ModuleLoadingState(),
          error: (e, _) => ModuleErrorState(
            title: 'Erro ao carregar subscrição de tenantes',
            message: e.toString(),
            onRetry: () => ref.invalidate(platformTenantsProvider),
          ),
          data: (tenants) => _TenantsTable(
            tenants: tenants,
            currency: currency,
            dateFmt: dateFmt,
          ),
        ),
      ),
    );
  }

  Future<void> _createTenant(BuildContext context, WidgetRef ref) async {
    final result = await showRegisterTenantFormDialog(context);
    if (result == null || !context.mounted) return;

    // Sucesso: o dialog só fecha após a API concluir.
    if (result.created != null) {
      PharmaFeedback.success(context, 'Tenant criado com sucesso.');
      ref.read(platformTenantsProvider.notifier).refresh();
    }
  }
}

class _TenantsTable extends StatelessWidget {
  const _TenantsTable({
    required this.tenants,
    required this.currency,
    required this.dateFmt,
  });

  final List<PlatformTenantSummary> tenants;
  final NumberFormat currency;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    if (tenants.isEmpty) {
      return const ModuleEmptyState(title: 'Nenhum tenant encontrado.');
    }

    return EnterpriseDataTable(
      columns: const [
        DataColumn(label: Text('Tenant')),
        DataColumn(label: Text('Plano')),
        DataColumn(label: Text('Preço Base')),
        DataColumn(label: Text('Filiais / Branches')),
        DataColumn(label: Text('Estado')),
        DataColumn(label: Text('Acções')),
      ],
      rowCount: tenants.length,
      rowBuilder: (context, index) {
        final t = tenants[index];
        return DataRow(
          cells: [
            DataCell(
              _TenantCell(
                title: t.tenantName,
                subtitle: t.companyName,
              ),
            ),
            DataCell(
              _PlanCell(
                planName: t.planName,
                monthlyValue: t.monthlyValue,
                currency: currency,
              ),
            ),
            DataCell(
              Text(
                t.monthlyValue == null
                    ? '—'
                    : currency.format(t.monthlyValue),
              ),
            ),
            DataCell(Text('${t.branchCount}')),
            DataCell(
              EnterpriseStatusChip(
                label: _tenantStatusLabel(t.status),
                color: _tenantStatusColor(context, t.status),
              ),
            ),
            DataCell(
              _TenantActionsMenuButton(
                tenant: t,
                currency: currency,
                dateFmt: dateFmt,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TenantCell extends StatelessWidget {
  const _TenantCell({
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
          style: theme.textTheme.bodySmall?.copyWith(
            color: tokens.textMuted,
          ),
        ),
      ],
    );
  }
}

class _PlanCell extends StatelessWidget {
  const _PlanCell({
    required this.planName,
    required this.monthlyValue,
    required this.currency,
  });

  final String? planName;
  final double? monthlyValue;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.pharmaTokens;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            planName ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall,
          ),
        ),
        if (monthlyValue != null) ...[
          const SizedBox(width: 8),
          EnterpriseStatusChip(
            label: currency.format(monthlyValue),
            color: tokens.posInfo,
          ),
        ],
      ],
    );
  }
}

enum _TenantAction {
  moreInfo,
  history,
  addBranch,
}

class _TenantActionsMenuButton extends StatelessWidget {
  const _TenantActionsMenuButton({
    required this.tenant,
    required this.currency,
    required this.dateFmt,
  });

  final PlatformTenantSummary tenant;
  final NumberFormat currency;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    return EnterpriseActionsMenuButton<_TenantAction>(
      tooltip: 'Acções do tenant',
      items: const [
        EnterpriseDropdownItem<_TenantAction>(
          value: _TenantAction.moreInfo,
          label: 'Mais informações',
          icon: Icons.info_outline_rounded,
        ),
        EnterpriseDropdownItem<_TenantAction>(
          value: _TenantAction.history,
          label: 'Histórico',
          icon: Icons.history_rounded,
        ),
        EnterpriseDropdownItem<_TenantAction>(
          value: _TenantAction.addBranch,
          label: '+ Branch / Filial',
          icon: Icons.add_business_outlined,
        ),
      ],
      onSelected: (action) async {
        switch (action) {
          case _TenantAction.moreInfo:
            EnterpriseOverlay.show<void>(
              context: context,
              title: const Text('Mais informações'),
              subtitle: '${tenant.tenantName} • ${tenant.companyName}',
              icon: Icons.info_outline_rounded,
              body: _TenantMoreInfoSheet(
                tenantId: tenant.id,
                currency: currency,
                dateFmt: dateFmt,
              ),
            );
          case _TenantAction.history:
            EnterpriseOverlay.show<void>(
              context: context,
              title: const Text('Histórico do tenant'),
              subtitle: '${tenant.tenantName} • ${tenant.companyName}',
              icon: Icons.history_rounded,
              size: EnterpriseOverlaySize.large,
              desktopSurface: EnterpriseDesktopSurface.sideSheet,
              body: _TenantHistorySheet(
                tenantId: tenant.id,
                dateFmt: DateFormat('dd/MM/yyyy HH:mm'),
              ),
            );
          case _TenantAction.addBranch:
            final created = await showCreateBranchFormDialog(
              context,
              tenantId: tenant.id,
            );
            if (created == null || !context.mounted) return;
            PharmaFeedback.success(
              context,
              'Filial ${created.code} criada. Extras serão cobrados na próxima renovação.',
            );
        }
      },
    );
  }
}

class _TenantMoreInfoSheet extends ConsumerWidget {
  const _TenantMoreInfoSheet({
    required this.tenantId,
    required this.currency,
    required this.dateFmt,
  });

  final String tenantId;
  final NumberFormat currency;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(platformTenantDetailProvider(tenantId));

    return async.when(
      loading: () => const ModuleLoadingState(itemCount: 3),
      error: (e, _) => ModuleErrorState(
        title: 'Erro ao carregar o tenant',
        message: e.toString(),
        onRetry: () => invalidateTenantBilling(ref, tenantId),
      ),
      data: (detail) {
        final summary = detail.summary;
        final subscription = detail.subscription;
        final includedBranches = subscription?.includedBranches ?? 0;
        final activeBranches = subscription?.activeBranches ??
            detail.branches.where((branch) => branch.active).length;
        final nextRenewal = subscription?.nextBillingAt == null
            ? '—'
            : dateFmt.format(subscription!.nextBillingAt!.toLocal());
        final lastInvoice = subscription?.lastInvoiceNumber == null
            ? '—'
            : [
                subscription!.lastInvoiceNumber,
                if (subscription.lastInvoiceStatus != null)
                  _tenantStatusLabel(subscription.lastInvoiceStatus!),
                if (subscription.lastInvoiceAmount != null)
                  currency.format(subscription.lastInvoiceAmount),
              ].join(' • ');
        final trialEndsAt = subscription?.trialEndsAt == null
            ? '—'
            : dateFmt.format(subscription!.trialEndsAt!.toLocal());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            EnterpriseListCard(
              title: 'Tenant',
              subtitle: summary.tenantName,
              leading: Icons.business_rounded,
            ),
            EnterpriseListCard(
              title: 'Empresa',
              subtitle: summary.companyName,
              leading: Icons.apartment_rounded,
            ),
            EnterpriseListCard(
              title: 'Plano',
              subtitle: subscription?.planName ?? summary.planName ?? '—',
              leading: Icons.layers_outlined,
            ),
            EnterpriseListCard(
              title: 'Filiais incluídas',
              subtitle: '$includedBranches',
              leading: Icons.store_mall_directory_outlined,
            ),
            EnterpriseListCard(
              title: 'Filiais activas',
              subtitle: '$activeBranches',
              leading: Icons.storefront_outlined,
            ),
            EnterpriseListCard(
              title: 'Próxima renovação',
              subtitle: nextRenewal,
              leading: Icons.event_repeat_rounded,
            ),
            EnterpriseListCard(
              title: 'Última fatura',
              subtitle: lastInvoice,
              leading: Icons.receipt_long_outlined,
            ),
            EnterpriseListCard(
              title: 'Fim do trial',
              subtitle: trialEndsAt,
              leading: Icons.hourglass_bottom_rounded,
              chip: EnterpriseStatusChip(
                label: _tenantStatusLabel(subscription?.status ?? summary.status),
                color: _tenantStatusColor(
                  context,
                  subscription?.status ?? summary.status,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TenantHistorySheet extends ConsumerWidget {
  const _TenantHistorySheet({
    required this.tenantId,
    required this.dateFmt,
  });

  final String tenantId;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(platformTenantBranchHistoryProvider(tenantId));

    return async.when(
      loading: () => const ModuleLoadingState(itemCount: 4),
      error: (e, _) => ModuleErrorState(
        title: 'Erro ao carregar histórico',
        message: e.toString(),
        onRetry: () =>
            ref.invalidate(platformTenantBranchHistoryProvider(tenantId)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const ModuleEmptyState(
            title: 'Sem histórico disponível para este tenant.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in items)
              EnterpriseListCard(
                title: item.branchName ?? 'Filial sem identificação',
                subtitle: '${item.action} • ${dateFmt.format(item.effectiveDate.toLocal())}',
                leading: item.action == 'ADD'
                    ? Icons.add_business_outlined
                    : Icons.history_toggle_off_rounded,
                chip: EnterpriseStatusChip(
                  label: item.action,
                  color: item.action == 'ADD'
                      ? _tenantStatusColor(context, 'active')
                      : _tenantStatusColor(context, 'suspenso'),
                ),
                metadata: [
                  if (item.branchCode != null)
                    EnterpriseListCardMeta(label: 'Código: ${item.branchCode}'),
                  EnterpriseListCardMeta(
                    label: 'Utilizador: ${item.createdByName ?? item.createdByEmail ?? '—'}',
                  ),
                  EnterpriseListCardMeta(
                    label: 'Motivo: ${item.reason ?? '—'}',
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

String _tenantStatusLabel(String raw) {
  switch (raw.toLowerCase()) {
    case 'trial':
      return 'Trial';
    case 'ativo':
    case 'active':
      return 'Activo';
    case 'suspenso':
    case 'suspended':
      return 'Suspenso';
    case 'expirado':
    case 'expired':
      return 'Expirado';
    case 'cancelado':
      return 'Cancelado';
    case 'grace':
      return 'Período de graça';
    case 'pendente':
      return 'Pendente';
    case 'parcial':
      return 'Parcial';
    case 'pago':
    case 'paga':
      return 'Paga';
    case 'vencido':
    case 'vencida':
      return 'Vencida';
    case 'confirmado':
      return 'Confirmado';
    default:
      return raw.toUpperCase();
  }
}

Color? _tenantStatusColor(BuildContext context, String raw) {
  final tokens = context.pharmaTokens;

  switch (raw.toLowerCase()) {
    case 'trial':
      return tokens.posInfo;
    case 'ativo':
    case 'active':
    case 'pago':
    case 'paga':
    case 'confirmado':
      return tokens.posSuccess;
    case 'grace':
    case 'parcial':
    case 'pendente':
      return tokens.posWarning;
    case 'suspenso':
    case 'expired':
    case 'expirado':
    case 'vencido':
    case 'vencida':
    case 'cancelado':
    case 'falhado':
      return tokens.posDanger;
    default:
      return null;
  }
}
