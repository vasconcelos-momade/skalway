import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../domain/mappers/finance_dashboard_kpis.dart';
import '../../domain/mappers/finance_dashboard_tables.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/charts/finance_dashboard_charts.dart';
import '../widgets/dashboard_charts_section.dart';
import '../widgets/dashboard_kpi_section.dart';
import '../widgets/dashboard_scaffold.dart';
import '../widgets/dashboard_widgets.dart';

class FinanceDashboardPage extends ConsumerWidget {
  const FinanceDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataSource = ref.watch(dashboardRemoteDataSourceProvider);

    return DashboardScaffold(
      title: 'Painel Financeiro',
      subtitle: 'Como está a saúde financeira da empresa?',
      provider: financeDashboardProvider.call,
      filterPresetBuilder: (preview) {
        final tables = DashboardDataUtils.map(preview?['tables']);
        return DashboardFilterPreset(
          statusOptions: dashboardUniqueOptions(
            DashboardDataUtils.list(tables?['ultimosPagamentos'])
                .map((row) => row['status']),
          ),
        );
      },
      loadingKpiCount: 8,
      contentBuilder: (context, data, query) {
        final kpis = DashboardDataUtils.map(data['kpis']);
        final charts = DashboardDataUtils.map(data['charts']);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardKpiSection(
              kpis: FinanceDashboardKpis.build(context, kpis),
            ),
            const DashboardSectionGap(),
            DashboardChartsSection(
              charts: FinanceDashboardCharts.build(context, charts),
            ),
            const DashboardSectionGap(),
            DashboardTablesSection(
              definitions: FinanceDashboardTables.definitions,
              fetcher: financeTableFetcher(dataSource),
              query: query,
            ),
          ],
        );
      },
    );
  }
}
