import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/report_paths.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../shared/widgets/cards/enterprise_kpi_grid.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/navigation/app_nav_config.dart';
import '../../../dashboard/data/datasources/dashboard_remote_datasource.dart';
import '../../../dashboard/domain/dashboard_query.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../../shared/widgets/dashboard/enterprise_filter_bar.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../../reports/presentation/controllers/report_controller.dart';
import '../widgets/finance_report_exports.dart';

/// Receita / Faturamento — apenas vendas realizadas (não saldo físico de caixa).
class RevenuePage extends ConsumerStatefulWidget {
  const RevenuePage({super.key});

  @override
  ConsumerState<RevenuePage> createState() => _RevenuePageState();
}

class _RevenuePageState extends ConsumerState<RevenuePage> {
  var _query = const DashboardQuery();

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(financeDashboardProvider(_query));
    final reportState = ref.watch(reportControllerProvider);
    final dataSource = ref.watch(dashboardRemoteDataSourceProvider);
    final kpis = dashMap(async.valueOrNull?['kpis']);

    return EnterpriseModuleHub(
      title: 'Receita / Faturamento',
      subtitle: 'Apenas vendas realizadas — separado do saldo físico de caixa.',
      tag: AppNavSections.finance,
      scrollable: true,
      mobileKpisHorizontalScroll: true,
      actions: [
        ...financeReportActions(
          ref: ref,
          enabled: !reportState.isSubmitting,
          path: ReportPaths.dashboardFinance,
          queryParameters: _query.toParams(),
        ),
        OutlinedButton.icon(
          onPressed: () => ref.invalidate(financeDashboardProvider(_query)),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
      ],
      filters: EnterpriseFilterBar(
        query: _query,
        onChanged: (query) => setState(() => _query = query),
      ),
      kpis: kpis == null
          ? null
          : [
              dashboardKpiCard(
                title: 'Receita / Faturamento',
                value: '${dashKpi(kpis, 'faturamento')} MZN',
                icon: Icons.trending_up,
                accent: StatCardAccent.positive,
              ),
              dashboardKpiCard(
                title: 'Nº de vendas',
                value: dashKpi(kpis, 'numVendas'),
                icon: Icons.receipt_long_outlined,
                accent: StatCardAccent.neutral,
              ),
              dashboardKpiCard(
                title: 'Ticket médio',
                value: '${dashKpi(kpis, 'ticketMedio')} MZN',
                icon: Icons.confirmation_number_outlined,
                accent: StatCardAccent.info,
              ),
              dashboardKpiCard(
                title: 'Lucro bruto',
                value: '${dashKpi(kpis, 'lucroBruto')} MZN',
                icon: Icons.stacked_line_chart,
                accent: StatCardAccent.positive,
              ),
            ],
      child: dashboardAsyncBody(
        async: async,
        onRetry: () => ref.invalidate(financeDashboardProvider(_query)),
        builder: (_) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardPaginatedTable(
              title: 'Vendas realizadas',
              headers: const ['Data', 'Tipo', 'Referência', 'Valor (MZN)'],
              reloadKey: '${_query.reloadKey}-receitas',
              loadPage: (page, pageSize, sortBy, sortDir) async {
                final result = await dataSource.financeDashboardTable(
                  table: 'ultimasReceitas',
                  query: _query.copyWith(
                    sortBy: sortBy,
                    sortDir: sortDir,
                    clearSortBy: sortBy == null,
                  ),
                  page: page,
                  pageSize: pageSize,
                );
                return DashboardPagedTableResult.fromMap(result);
              },
              rowBuilder: (row) => [
                dashLabel(row['createdAt']),
                row['tipo']?.toString() ?? '—',
                row['referencia']?.toString() ?? '—',
                '${row['valor'] ?? 0} MZN',
              ],
            ),
          ],
        ),
      ),
    );
  }
}
