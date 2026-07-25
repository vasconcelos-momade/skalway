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
import '../../../dashboard/presentation/widgets/dashboard_period_filters.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../../reports/presentation/controllers/report_controller.dart';
import '../widgets/finance_report_exports.dart';

class ExpensesPage extends ConsumerStatefulWidget {
  const ExpensesPage({super.key});

  @override
  ConsumerState<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends ConsumerState<ExpensesPage> {
  var _query = const DashboardQuery();

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(financeDashboardProvider(_query));
    final reportState = ref.watch(reportControllerProvider);
    final dataSource = ref.watch(dashboardRemoteDataSourceProvider);
    final kpis = dashMap(async.valueOrNull?['kpis']);

    return EnterpriseModuleHub(
      title: 'Despesas',
      subtitle: 'Movimentos de despesa, compras e reembolsos.',
      tag: AppNavSections.finance,
      scrollable: true,
      mobileKpisHorizontalScroll: true,
      actions: [
        ...financeReportActions(
          ref: ref,
          enabled: !reportState.isSubmitting,
          path: ReportPaths.financeExpenses,
          queryParameters: _query.toParams(),
        ),
        OutlinedButton.icon(
          onPressed: () => ref.invalidate(financeDashboardProvider(_query)),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Atualizar'),
        ),
      ],
      filters: DashboardPeriodFilters(
        query: _query,
        onChanged: (query) => setState(() => _query = query),
      ),
      kpis: kpis == null
          ? null
          : [
              dashboardKpiCard(
                title: 'Despesas',
                value: '${dashKpi(kpis, 'despesas')} MZN',
                icon: Icons.trending_down,
                accent: StatCardAccent.warning,
              ),
              dashboardKpiCard(
                title: 'A pagar',
                value: '${dashKpi(kpis, 'contasPagar')} MZN',
                icon: Icons.call_made,
                accent: StatCardAccent.warning,
              ),
              dashboardKpiCard(
                title: 'Pag. pendentes',
                value: dashKpi(kpis, 'pagamentosPendentes'),
                icon: Icons.pending_outlined,
              ),
              dashboardKpiCard(
                title: 'Lucro',
                value: '${dashKpi(kpis, 'lucro')} MZN',
                icon: Icons.percent,
                accent: StatCardAccent.info,
              ),
            ],
      child: dashboardAsyncBody(
        async: async,
        onRetry: () => ref.invalidate(financeDashboardProvider(_query)),
        builder: (_) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardPaginatedTable(
              title: 'Despesas',
              headers: const ['Data', 'Tipo', 'Referência', 'Valor (MZN)'],
              reloadKey: '${_query.reloadKey}-despesas',
              loadPage: (page, pageSize, sortBy, sortDir) async {
                final result = await dataSource.financeDashboardTable(
                  table: 'ultimasDespesas',
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
