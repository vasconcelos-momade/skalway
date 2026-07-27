import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../dashboard_charts_section.dart';
import '../dashboard_widgets.dart';

abstract final class PharmacyDashboardCharts {
  PharmacyDashboardCharts._();

  static List<Widget> build(BuildContext context, Map<String, dynamic>? charts) {
    final t = context.pharmaTokens;
    final vendasPorHora = DashboardDataUtils.list(charts?['vendasPorHora']);
    final topProdutos =
        DashboardDataUtils.list(charts?['produtosMaisDispensados']);
    final categorias = DashboardDataUtils.list(charts?['produtosPorCategoria']);
    final validades = DashboardDataUtils.map(charts?['validades']) ?? const {};
    final movimentos = DashboardDataUtils.list(charts?['entradasSaidas']);

    return [
      DashboardChartSlot(
        fullWidth: true,
        child: dashboardChartCard(
          context: context,
          title: 'Vendas por hora',
          child: dashboardLineChart(
            context: context,
            points: vendasPorHora,
            valueKey: 'total',
            labelKey: 'hora',
            color: t.brandGreen,
          ),
        ),
      ),
      dashboardChartCard(
        context: context,
        title: 'Produtos mais vendidos',
        child: dashboardRankedBarList(
          context: context,
          points: topProdutos.take(10).toList(growable: false),
          valueKey: 'quantidade',
          labelKey: 'produtoNomeComercial',
          color: t.brandBlue,
        ),
      ),
      dashboardChartCard(
        context: context,
        title: 'Vendas por categoria',
        child: dashboardPieChart(
          context: context,
          slices: [
            for (var i = 0; i < categorias.length; i++)
              DashboardPieSlice(
                label: DashboardDataUtils.text(categorias[i]['categoria']),
                value:
                    (categorias[i]['totalProdutos'] as num?)?.toDouble() ?? 0,
                color: _palette(t)[i % _palette(t).length],
              ),
          ],
        ),
      ),
      dashboardChartCard(
        context: context,
        title: 'Validade de produtos',
        child: dashboardIndexedBarChart(
          context: context,
          labels: const ['Exp.', '30d', '60d', '90d'],
          values: [
            (validades['lotesExpirados'] as num?)?.toDouble() ?? 0,
            (validades['expiramEm30Dias'] as num?)?.toDouble() ?? 0,
            (validades['expiramEm60Dias'] as num?)?.toDouble() ?? 0,
            (validades['expiramEm90Dias'] as num?)?.toDouble() ?? 0,
          ],
          barColors: [t.posDanger, t.posWarning, t.brandBlue, t.brandGreen],
          barWidth: 24,
        ),
      ),
      dashboardChartCard(
        context: context,
        title: 'Movimentação de estoque',
        child: dashboardBarChart(
          context: context,
          points: movimentos,
          valueKey: 'quantidade',
          labelKey: 'tipo',
          color: t.brandBlue,
        ),
      ),
    ];
  }

  static List<Color> _palette(dynamic t) => [
        t.brandGreen,
        t.brandBlue,
        t.posWarning,
        t.posDanger,
        t.textSecondary,
      ];
}
