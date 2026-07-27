import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../dashboard_charts_section.dart';
import '../dashboard_widgets.dart';

abstract final class ExecutiveDashboardCharts {
  ExecutiveDashboardCharts._();

  static List<Widget> build(BuildContext context, Map<String, dynamic>? charts) {
    final t = context.pharmaTokens;
    final fluxoFinanceiro = DashboardDataUtils.list(charts?['fluxoFinanceiro']);
    final receitaMensal = DashboardDataUtils.list(charts?['receitaMensal']);
    final topProdutos = DashboardDataUtils.list(charts?['topProdutos']);
    final topCategorias = DashboardDataUtils.list(charts?['topCategorias']);

    return [
      DashboardChartSlot(
        fullWidth: true,
        child: dashboardChartCard(
          context: context,
          title: 'Receita x Lucro Líquido',
          child: dashboardMultiLineChart(
            context: context,
            points: fluxoFinanceiro,
            labelKey: 'data',
            fillFirstSeries: true,
            series: [
              DashboardLineSeries(
                key: 'receitas',
                label: 'Receita',
                color: t.brandGreen,
              ),
              DashboardLineSeries(
                key: 'saldo',
                label: 'Resultado',
                color: t.brandBlue,
              ),
            ],
          ),
        ),
      ),
      dashboardChartCard(
        context: context,
        title: 'Fluxo de caixa',
        child: dashboardGroupedCashFlowChart(
          context: context,
          points: fluxoFinanceiro,
          labelKey: 'data',
        ),
      ),
      dashboardChartCard(
        context: context,
        title: 'Top 10 produtos',
        child: dashboardRankedBarList(
          context: context,
          points: topProdutos.take(10).toList(growable: false),
          valueKey: 'total',
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
            for (var i = 0; i < topCategorias.length; i++)
              DashboardPieSlice(
                label: DashboardDataUtils.text(topCategorias[i]['categoria']),
                value: (topCategorias[i]['total'] as num?)?.toDouble() ?? 0,
                color: _palette(t)[i % _palette(t).length],
              ),
          ],
        ),
      ),
      dashboardChartCard(
        context: context,
        title: 'Evolução mensal',
        child: dashboardLineChart(
          context: context,
          points: receitaMensal,
          valueKey: 'total',
          labelKey: 'mes',
          color: t.brandGreen,
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
