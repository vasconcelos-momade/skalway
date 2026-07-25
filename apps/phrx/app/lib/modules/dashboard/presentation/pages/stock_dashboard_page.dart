import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/report_paths.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../domain/mappers/stock_dashboard_kpis.dart';
import '../../domain/mappers/stock_dashboard_tables.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/charts/stock_dashboard_charts.dart';
import '../widgets/dashboard_charts_section.dart';
import '../widgets/dashboard_kpi_section.dart';
import '../widgets/dashboard_scaffold.dart';
import '../widgets/dashboard_widgets.dart';

class StockDashboardPage extends ConsumerWidget {
  const StockDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataSource = ref.watch(dashboardRemoteDataSourceProvider);

    return DashboardScaffold(
      title: 'Painel de Stock',
      subtitle: 'Visão operacional de inventário e movimentações.',
      provider: stockDashboardProvider.call,
      reportPath: ReportPaths.dashboardStock,
      exportSuccessMessage: 'Exportação do painel stock concluída.',
      filterPresetBuilder: (preview) {
        final tables = DashboardDataUtils.map(preview?['tables']);
        final charts = DashboardDataUtils.map(preview?['charts']);
        return DashboardFilterPreset(
          actionsInFilters: true,
          showProductFilter: true,
          statusOptions: dashboardUniqueOptions([
            ...DashboardDataUtils.list(tables?['inventarios'])
                .map((row) => row['status']),
            ...DashboardDataUtils.list(tables?['entradasCompra'])
                .map((row) => row['fornecedorNome']),
          ]),
          movementTypeOptions: dashboardUniqueOptions(
            [
              ...DashboardDataUtils.list(charts?['entradasSaidas'])
                  .map((row) => row['tipo']),
              ...DashboardDataUtils.list(tables?['ultimosMovimentos'])
                  .map((row) => row['tipo']),
            ],
            labels: const {
              'ENTRADA': 'Entrada',
              'COMPRA': 'Compra',
              'SAIDA': 'Saída',
              'AJUSTE': 'Ajuste',
            },
          ),
        );
      },
      contentBuilder: (context, data, query) {
        final kpis = DashboardDataUtils.map(data['kpis']);
        final charts = DashboardDataUtils.map(data['charts']);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardKpiSection(
              primaryKpis: StockDashboardKpis.primary(kpis),
            ),
            const DashboardSectionGap(),
            DashboardChartsSection(
              charts: StockDashboardCharts.build(context, charts),
            ),
            const DashboardSectionGap(),
            DashboardTablesSection(
              definitions: StockDashboardTables.definitions,
              fetcher: stockTableFetcher(dataSource),
              query: query,
            ),
          ],
        );
      },
    );
  }
}
