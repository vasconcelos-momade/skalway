import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../domain/mappers/cashier_dashboard_kpis.dart';
import '../../domain/mappers/cashier_dashboard_tables.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/charts/cashier_dashboard_charts.dart';
import '../widgets/dashboard_charts_section.dart';
import '../widgets/dashboard_kpi_section.dart';
import '../widgets/dashboard_scaffold.dart';
import '../widgets/dashboard_widgets.dart';

class CashierDashboardPage extends ConsumerWidget {
  const CashierDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataSource = ref.watch(dashboardRemoteDataSourceProvider);

    return DashboardScaffold(
      title: 'Painel do Caixa',
      subtitle:
          'Operação diária do terminal: vendas, caixa e formas de pagamento.',
      provider: cashierDashboardProvider.call,
      loadingKpiCount: 6,
      contentBuilder: (context, data, query) {
        final kpis = DashboardDataUtils.map(data['kpis']);
        final charts = DashboardDataUtils.map(data['charts']);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardKpiSection(
              kpis: CashierDashboardKpis.build(context, kpis),
            ),
            const DashboardSectionGap(),
            DashboardChartsSection(
              charts: CashierDashboardCharts.build(context, charts),
            ),
            const DashboardSectionGap(),
            DashboardTablesSection(
              definitions: CashierDashboardTables.definitions,
              fetcher: cashierTableFetcher(dataSource),
              query: query,
            ),
          ],
        );
      },
    );
  }
}
