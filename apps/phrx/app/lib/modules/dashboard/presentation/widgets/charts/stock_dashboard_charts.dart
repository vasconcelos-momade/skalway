import 'package:flutter/material.dart';

import '../dashboard_charts_section.dart';
import '../dashboard_widgets.dart';

abstract final class StockDashboardCharts {
  StockDashboardCharts._();

  static List<Widget> build(BuildContext context, Map<String, dynamic>? charts) {
    final scheme = Theme.of(context).colorScheme;
    final composicao =
        DashboardDataUtils.map(charts?['composicaoLotes']) ?? const {};

    return [
      dashboardChartCard(
        context: context,
        title: 'Composição de lotes',
        child: dashboardIndexedBarChart(
          context: context,
          labels: const ['Total', 'Disp.', 'Sanit.', 'Reserv.', 'Exp.'],
          values: [
            (composicao['totalLotes'] as num?)?.toDouble() ?? 0,
            (composicao['lotesDisponiveis'] as num?)?.toDouble() ?? 0,
            (composicao['lotesSanitarios'] as num?)?.toDouble() ?? 0,
            (composicao['lotesReservados'] as num?)?.toDouble() ?? 0,
            (composicao['lotesExpirados'] as num?)?.toDouble() ?? 0,
          ],
        ),
      ),
      dashboardChartCard(
        context: context,
        title: 'Entradas x saídas',
        child: dashboardBarChart(
          context: context,
          points: DashboardDataUtils.list(charts?['entradasSaidas']),
          valueKey: 'quantidade',
          labelKey: 'tipo',
          color: scheme.primary,
        ),
      ),
      DashboardChartSlot(
        fullWidth: true,
        child: dashboardChartCard(
          context: context,
          title: 'Movimentação mensal',
          child: dashboardDualLineChart(
            context: context,
            points: DashboardDataUtils.list(charts?['movimentacaoMensal']).map(
              (row) => {
                'receitas': row['entradas'],
                'despesas': row['saidas'],
                'mes': row['mes'],
              },
            ).toList(),
          ),
        ),
      ),
      dashboardChartCard(
        context: context,
        title: 'Produtos mais movimentados',
        child: dashboardBarChart(
          context: context,
          points: DashboardDataUtils.list(charts?['produtosMaisMovimentados']),
          valueKey: 'quantidade',
          labelKey: 'produtoNomeComercial',
          color: scheme.secondary,
        ),
      ),
      dashboardChartCard(
        context: context,
        title: 'Valor stock por categoria',
        child: dashboardBarChart(
          context: context,
          points: DashboardDataUtils.list(charts?['valorStockPorCategoria']),
          valueKey: 'valor',
          labelKey: 'categoria',
          color: scheme.tertiary,
        ),
      ),
    ];
  }
}
