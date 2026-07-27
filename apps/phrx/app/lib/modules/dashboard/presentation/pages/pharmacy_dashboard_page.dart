import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../domain/mappers/pharmacy_dashboard_kpis.dart';
import '../../domain/mappers/pharmacy_dashboard_tables.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/charts/pharmacy_dashboard_charts.dart';
import '../widgets/dashboard_charts_section.dart';
import '../widgets/dashboard_kpi_section.dart';
import '../widgets/dashboard_scaffold.dart';
import '../widgets/dashboard_widgets.dart';

class PharmacyDashboardPage extends ConsumerWidget {
  const PharmacyDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataSource = ref.watch(dashboardRemoteDataSourceProvider);

    return DashboardScaffold(
      title: 'Painel Farmácia',
      subtitle: 'Como está a operação da farmácia? Estoque, vendas e validades.',
      provider: pharmacyDashboardProvider.call,
      loadingKpiCount: 8,
      contentBuilder: (context, data, query) {
        final kpis = DashboardDataUtils.map(data['kpis']);
        final charts = DashboardDataUtils.map(data['charts']);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardKpiSection(
              kpis: PharmacyDashboardKpis.build(context, kpis),
            ),
            const DashboardSectionGap(),
            DashboardChartsSection(
              charts: PharmacyDashboardCharts.build(context, charts),
            ),
            const DashboardSectionGap(),
            DashboardTablesSection(
              definitions: PharmacyDashboardTables.definitions,
              fetcher: pharmacyTableFetcher(dataSource),
              query: query,
            ),
          ],
        );
      },
    );
  }
}
