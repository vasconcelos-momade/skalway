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

class PlatformDashboardPage extends ConsumerWidget {
  const PlatformDashboardPage({super.key});

  static final _currency = NumberFormat.currency(symbol: 'MT ', decimalDigits: 0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(platformDashboardProvider);

    return EnterpriseModuleHub(
      title: 'Dashboard',
      subtitle: 'Visão executiva da plataforma SaaS.',
      tag: 'Plataforma',
      scrollable: true,
      actions: [
        OutlinedButton.icon(
          onPressed: () =>
              ref.read(platformDashboardProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
      ],
      kpis: async.maybeWhen(
        data: (stats) => [
          EnterpriseStatCard(
            title: 'Total Clientes',
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
              const SizedBox(height: 8),
              ...stats.alerts.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: EnterpriseListCard(
                    title: a,
                    leading: Icons.warning_amber_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text('Últimos clientes',
                style: Theme.of(context).textTheme.erpSectionTitle),
            const SizedBox(height: 12),
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
                    DataCell(Text(t.companyName)),
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
    );
  }
}
