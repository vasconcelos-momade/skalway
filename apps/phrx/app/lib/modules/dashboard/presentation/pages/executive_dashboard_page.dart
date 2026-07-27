import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../domain/mappers/executive_dashboard_kpis.dart';
import '../../domain/mappers/executive_dashboard_tables.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/charts/executive_dashboard_charts.dart';
import '../widgets/dashboard_alerts_panel.dart';
import '../widgets/dashboard_charts_section.dart';
import '../widgets/dashboard_kpi_section.dart';
import '../widgets/dashboard_scaffold.dart';
import '../widgets/dashboard_widgets.dart';

class ExecutiveDashboardPage extends ConsumerWidget {
  const ExecutiveDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataSource = ref.watch(dashboardRemoteDataSourceProvider);

    return DashboardScaffold(
      title: 'Painel Executivo',
      subtitle: 'Como está a empresa? Visão estratégica de crescimento e rentabilidade.',
      provider: executiveDashboardProvider.call,
      loadingKpiCount: 8,
      contentBuilder: (context, data, query) {
        final kpis = DashboardDataUtils.map(data['kpis']);
        final charts = DashboardDataUtils.map(data['charts']);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardKpiSection(
              kpis: ExecutiveDashboardKpis.build(context, kpis),
            ),
            const DashboardSectionGap(),
            DashboardChartsSection(
              charts: ExecutiveDashboardCharts.build(context, charts),
            ),
            const DashboardSectionGap(),
            DashboardTablesSection(
              definitions: ExecutiveDashboardTables.definitions,
              fetcher: executiveTableFetcher(dataSource),
              query: query,
            ),
            const DashboardSectionGap(),
            DashboardAlertsPanel.fromExecutiveKpis(kpis),
          ],
        );
      },
    );
  }
}
