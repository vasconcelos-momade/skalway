import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/report_paths.dart';
import '../../domain/mappers/pharmacy_dashboard_kpis.dart';
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
    return DashboardScaffold(
      title: 'Painel Farmácia',
      subtitle:
          'Visão operacional de produtos, stock, validades e alertas sanitários.',
      provider: pharmacyDashboardProvider.call,
      reportPath: ReportPaths.dashboardPharmacy,
      exportSuccessMessage: 'Exportação do painel farmácia concluída.',
      filterPreset: const DashboardFilterPreset(actionsInFilters: true),
      contentBuilder: (context, data, _) {
        final kpis = DashboardDataUtils.map(data['kpis']);
        final charts = DashboardDataUtils.map(data['charts']);
        final tables = DashboardDataUtils.map(data['tables']);
        final criticos = DashboardDataUtils.list(tables?['produtosCriticos'])
            .take(5)
            .toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardKpiSection(
              primaryKpis: PharmacyDashboardKpis.primary(kpis),
            ),
            const DashboardSectionGap(),
            DashboardChartsSection(
              charts: PharmacyDashboardCharts.build(context, charts),
            ),
            const DashboardSectionGap(),
            dashboardSimpleTable(
              context: context,
              title: 'Produtos críticos',
              headers: const ['Produto', 'Stock', 'Mínimo', 'Validade'],
              rows: [
                for (final row in criticos)
                  [
                    DashboardDataUtils.text(row['nome']),
                    DashboardDataUtils.text(row['disponivel']),
                    DashboardDataUtils.text(row['minimo']),
                    DashboardDataUtils.label(row['validade']),
                  ],
              ],
              emptySubtitle: 'Sem produtos críticos no momento.',
            ),
          ],
        );
      },
    );
  }
}
