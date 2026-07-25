import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/report_paths.dart';
import '../../domain/mappers/executive_dashboard_kpis.dart';
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
    return DashboardScaffold(
      title: 'Painel Executivo',
      subtitle:
          'Visão consolidada de vendas, finanças, stock e alertas operacionais.',
      provider: executiveDashboardProvider.call,
      reportPath: ReportPaths.dashboardExecutive,
      exportSuccessMessage: 'Exportação do painel executivo concluída.',
      filterPreset: const DashboardFilterPreset(),
      contentBuilder: (context, data, _) {
        final kpis = DashboardDataUtils.map(data['kpis']);
        final charts = DashboardDataUtils.map(data['charts']);
        final tables = DashboardDataUtils.map(data['tables']);
        final ultimasVendas = DashboardDataUtils.list(tables?['ultimasVendas'])
            .take(5)
            .toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardKpiSection(
              primaryKpis: ExecutiveDashboardKpis.primary(kpis),
            ),
            const DashboardSectionGap(),
            DashboardChartsSection(
              charts: ExecutiveDashboardCharts.build(context, charts),
            ),
            const DashboardSectionGap(),
            DashboardAlertsPanel.fromExecutiveKpis(kpis),
            const DashboardSectionGap(),
            dashboardSimpleTable(
              context: context,
              title: 'Últimas vendas',
              headers: const ['Fatura', 'Cliente', 'Total', 'Estado'],
              rows: [
                for (final row in ultimasVendas)
                  [
                    DashboardDataUtils.text(row['numero']),
                    DashboardDataUtils.text(row['clienteNome']),
                    DashboardDataUtils.money(row['total']),
                    DashboardDataUtils.text(row['estado']),
                  ],
              ],
              emptySubtitle: 'Sem vendas no período selecionado.',
            ),
          ],
        );
      },
    );
  }
}
