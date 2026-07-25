import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/report_paths.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/cards/enterprise_kpi_grid.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/navigation/app_nav_config.dart';
import '../../../dashboard/data/datasources/dashboard_remote_datasource.dart';
import '../../../dashboard/domain/dashboard_query.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../dashboard/presentation/widgets/dashboard_kpi_section.dart';
import '../../../dashboard/presentation/widgets/dashboard_period_filters.dart';
import '../../../dashboard/presentation/widgets/dashboard_widgets.dart';
import '../../../reports/presentation/controllers/report_controller.dart';
import '../widgets/finance_report_exports.dart';

class FinancialPage extends ConsumerStatefulWidget {
  const FinancialPage({super.key});

  @override
  ConsumerState<FinancialPage> createState() => _FinancialPageState();
}

class _FinancialPageState extends ConsumerState<FinancialPage> {
  var _query = const DashboardQuery();

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(financeDashboardProvider(_query));
    final reportState = ref.watch(reportControllerProvider);
    final dataSource = ref.watch(dashboardRemoteDataSourceProvider);
    final kpis = dashMap(async.valueOrNull?['kpis']);

    return EnterpriseModuleHub(
      title: 'Visão financeira',
      subtitle: 'DRE (receita, CMV, despesas) separado do saldo físico de caixa.',
      tag: AppNavSections.finance,
      scrollable: true,
      mobileKpisHorizontalScroll: true,
      actions: [
        ...financeReportActions(
          ref: ref,
          enabled: !reportState.isSubmitting,
          path: ReportPaths.financeAccountsReceivable,
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
      child: dashboardAsyncBody(
        async: async,
        onRetry: () => ref.invalidate(financeDashboardProvider(_query)),
        loadingKpiCount: 6,
        builder: (_) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (kpis != null) ...[
              DashboardKpiSection(
                primaryKpis: [
                  dashboardKpiCard(
                    title: 'Receita',
                    value: '${dashKpi(kpis, 'receita')} MZN',
                    icon: Icons.trending_up,
                    accent: StatCardAccent.positive,
                  ),
                  dashboardKpiCard(
                    title: 'CMV',
                    value: '${dashKpi(kpis, 'custos')} MZN',
                    icon: Icons.inventory_2_outlined,
                    accent: StatCardAccent.warning,
                  ),
                  dashboardKpiCard(
                    title: 'Lucro bruto',
                    value: '${dashKpi(kpis, 'lucroBruto')} MZN',
                    icon: Icons.stacked_line_chart,
                    accent: StatCardAccent.positive,
                  ),
                  dashboardKpiCard(
                    title: 'Despesas',
                    value: '${dashKpi(kpis, 'despesas')} MZN',
                    icon: Icons.trending_down,
                    accent: StatCardAccent.warning,
                  ),
                  dashboardKpiCard(
                    title: 'Lucro líquido',
                    value: '${dashKpi(kpis, 'lucroLiquido')} MZN',
                    icon: Icons.percent,
                    accent: StatCardAccent.positive,
                  ),
                  dashboardKpiCard(
                    title: 'Saldo caixa',
                    value: '${dashKpi(kpis, 'saldoAtual')} MZN',
                    icon: Icons.account_balance_wallet,
                    accent: StatCardAccent.info,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            DashboardPaginatedTable(
              title: 'Contas vencidas',
              headers: const ['Cliente', 'Saldo', 'Vencimento'],
              reloadKey: '${_query.reloadKey}-vencidas',
              loadPage: (page, pageSize, sortBy, sortDir) async {
                final result = await dataSource.financeDashboardTable(
                  table: 'contasVencidas',
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
                row['clienteNome']?.toString() ?? '—',
                '${row['saldo'] ?? 0} MZN',
                dashLabel(row['vencimento']),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            DashboardPaginatedTable(
              title: 'Últimos pagamentos',
              headers: const ['Fatura', 'Método', 'Valor'],
              reloadKey: '${_query.reloadKey}-pagamentos',
              loadPage: (page, pageSize, sortBy, sortDir) async {
                final result = await dataSource.financeDashboardTable(
                  table: 'ultimosPagamentos',
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
                row['faturaNumero']?.toString() ?? '—',
                row['metodo']?.toString() ?? '—',
                '${row['valor'] ?? 0} MZN',
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            DashboardPaginatedTable(
              title: 'Contas a receber',
              headers: const ['Cliente', 'Fatura', 'Saldo', 'Estado', 'Vencimento'],
              reloadKey: '${_query.reloadKey}-receber',
              loadPage: (page, pageSize, sortBy, sortDir) async {
                final result = await dataSource.financeDashboardTable(
                  table: 'contasReceber',
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
                row['clienteNome']?.toString() ?? '—',
                row['faturaNumero']?.toString() ?? '—',
                '${row['saldo'] ?? 0} MZN',
                row['status']?.toString() ?? '—',
                dashLabel(row['vencimento']),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            DashboardPaginatedTable(
              title: 'Contas a pagar',
              headers: const ['Fornecedor', 'Saldo', 'Estado', 'Vencimento'],
              reloadKey: '${_query.reloadKey}-pagar',
              loadPage: (page, pageSize, sortBy, sortDir) async {
                final result = await dataSource.financeDashboardTable(
                  table: 'contasPagar',
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
                row['fornecedorNome']?.toString() ?? '—',
                '${row['saldo'] ?? 0} MZN',
                row['status']?.toString() ?? '—',
                dashLabel(row['vencimento']),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
