import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/report_paths.dart';
import '../../../../shared/widgets/cards/enterprise_kpi_grid.dart';
import '../../domain/mappers/finance_dashboard_kpis.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/charts/finance_dashboard_charts.dart';
import '../widgets/dashboard_charts_section.dart';
import '../widgets/dashboard_scaffold.dart';
import '../widgets/dashboard_widgets.dart';

class FinanceDashboardPage extends ConsumerWidget {
  const FinanceDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardScaffold(
      title: 'Painel Financeiro',
      subtitle: 'Visão consolidada da operação de caixa e do desempenho comercial.',
      provider: financeDashboardProvider.call,
      reportPath: ReportPaths.dashboardFinance,
      exportSuccessMessage: 'Exportação do painel financeiro concluída.',
      filterPresetBuilder: (preview) {
        final tables = DashboardDataUtils.map(preview?['tables']);
        return DashboardFilterPreset(
          actionsInFilters: true,
          statusOptions: dashboardUniqueOptions(
            DashboardDataUtils.list(tables?['ultimosPagamentos'])
                .map((row) => row['status']),
          ),
        );
      },
      contentBuilder: (context, data, _) {
        final kpis = DashboardDataUtils.map(data['kpis']);
        final charts = DashboardDataUtils.map(data['charts']);
        final tables = DashboardDataUtils.map(data['tables']);
        final movimentos = <Map<String, dynamic>>[
          ...DashboardDataUtils.list(tables?['ultimasReceitas']).map(
            (row) => {...row, '_sentido': 'Receita'},
          ),
          ...DashboardDataUtils.list(tables?['ultimasDespesas']).map(
            (row) => {...row, '_sentido': 'Despesa'},
          ),
        ]..sort((a, b) {
            final aDate = a['createdAt']?.toString() ?? '';
            final bDate = b['createdAt']?.toString() ?? '';
            return bDate.compareTo(aDate);
          });
        final ultimos = movimentos.take(5).toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Operação de Caixa',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            EnterpriseKpiGrid(
              cards: FinanceDashboardKpis.cashOperation(kpis),
            ),
            const DashboardSectionGap(),
            Text(
              'Desempenho Comercial',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            EnterpriseKpiGrid(
              cards: FinanceDashboardKpis.commercial(kpis),
            ),
            const DashboardSectionGap(),
            DashboardChartsSection(
              charts: FinanceDashboardCharts.build(context, charts),
            ),
            const DashboardSectionGap(),
            dashboardSimpleTable(
              context: context,
              title: 'Últimas movimentações financeiras',
              headers: const ['Tipo', 'Referência', 'Valor', 'Data'],
              rows: [
                for (final row in ultimos)
                  [
                    DashboardDataUtils.text(
                      row['_sentido'] ?? row['tipo'],
                    ),
                    DashboardDataUtils.text(row['referencia']),
                    DashboardDataUtils.money(row['valor']),
                    DashboardDataUtils.label(row['createdAt']),
                  ],
              ],
              emptySubtitle: 'Sem movimentações no período selecionado.',
            ),
          ],
        );
      },
    );
  }
}
