import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../providers/platform_providers.dart';
import '../../../../shared/refresh/page_refresh.dart';

class PlatformDashboardPage extends ConsumerWidget {
  const PlatformDashboardPage({super.key});

  static final _currency = NumberFormat.currency(symbol: 'MT ', decimalDigits: 0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(platformDashboardProvider);

    return PageRefreshBinder(
      onRefresh: () => ref.read(platformDashboardProvider.notifier).refresh(),
      child: EnterpriseModuleHub(
      title: 'Dashboard',
      subtitle: 'Visão executiva da plataforma SaaS.',
      tag: 'Plataforma',
      scrollable: true,
      actions: [
      ],
      kpis: async.maybeWhen(
        data: (stats) => [
          EnterpriseStatCard(
            title: 'Total Tenantes',
            value: '${stats.totalClients}',
            icon: Icons.business_outlined,
          ),
          EnterpriseStatCard(
            title: 'Ativos',
            value: '${stats.activeClients}',
            icon: Icons.check_circle_outline,
            accent: StatCardAccent.positive,
          ),
          EnterpriseStatCard(
            title: 'Trial',
            value: '${stats.trialClients}',
            icon: Icons.hourglass_empty,
            accent: StatCardAccent.warning,
          ),
          EnterpriseStatCard(
            title: 'Suspensos',
            value: '${stats.suspendedClients}',
            icon: Icons.block_outlined,
            accent: StatCardAccent.danger,
          ),
          EnterpriseStatCard(
            title: 'Receita Mensal',
            value: _currency.format(stats.monthlyRevenue),
            icon: Icons.payments_outlined,
            accent: StatCardAccent.info,
          ),
          EnterpriseStatCard(
            title: 'Filiais',
            value: '${stats.totalBranches}',
            icon: Icons.store_outlined,
          ),
        ],
        orElse: () => null,
      ),
      child: async.when(
        loading: () => const ModuleLoadingState(),
        error: (e, _) => ModuleErrorState(
          title: 'Erro ao carregar',
          message: e.toString(),
          onRetry: () => ref.invalidate(platformDashboardProvider),
        ),
        data: (stats) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (stats.alerts.isNotEmpty) ...[
              Text('Alertas',
                  style: Theme.of(context).textTheme.erpSectionTitle),
              SizedBox(height: context.spacing.sm),
              ...stats.alerts.map(
                (a) => Padding(
                  padding: EdgeInsets.only(bottom: context.spacing.sm),
                  child: EnterpriseListCard(
                    title: a,
                    leading: Icons.warning_amber_outlined,
                  ),
                ),
              ),
              SizedBox(height: context.spacing.xl),
            ],
            Text('Últimos tenantes',
                style: Theme.of(context).textTheme.erpSectionTitle),
            SizedBox(height: context.spacing.md),
            EnterpriseDataTable(
              columns: const [
                DataColumn(label: Text('Empresa')),
                DataColumn(label: Text('Tenant')),
                DataColumn(label: Text('Estado')),
                DataColumn(label: Text('Plano')),
              ],
              rowCount: stats.recentTenants.length,
              rowBuilder: (context, index) {
                final t = stats.recentTenants[index];
                return DataRow(
                  onSelectChanged: (_) => context.go(
                    AppRoutePaths.platformTenantDetailPath(t.id),
                  ),
                  cells: [
                    DataCell(Text(t.tenantName)),
                    DataCell(Text(t.tenantName)),
                    DataCell(EnterpriseStatusChip(label: t.status)),
                    DataCell(Text(t.planName ?? '—')),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
    );
  }
}
