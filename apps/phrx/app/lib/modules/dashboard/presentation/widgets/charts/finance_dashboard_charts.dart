import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../dashboard_charts_section.dart';
import '../dashboard_widgets.dart';

abstract final class FinanceDashboardCharts {
  FinanceDashboardCharts._();

  static List<Widget> build(BuildContext context, Map<String, dynamic>? charts) {
    final t = context.pharmaTokens;
    final fluxoDiario = DashboardDataUtils.list(charts?['fluxoDiario']);
    final fluxoMensal = DashboardDataUtils.list(charts?['fluxoMensal']);
    final metodosPagamento = DashboardDataUtils.list(charts?['metodosPagamento']);
    final despesasCategoria = DashboardDataUtils.list(charts?['despesasPorCategoria']);
    final recebimentos = DashboardDataUtils.list(charts?['recebimentosPorCategoria']);

    return [
      DashboardChartSlot(
        fullWidth: true,
        child: dashboardChartCard(
          context: context,
          title: 'DRE Financeira',
          child: dashboardMultiLineChart(
            context: context,
            points: fluxoMensal,
            labelKey: 'mes',
            series: [
              DashboardLineSeries(
                key: 'receitas',
                label: 'Receita',
                color: t.brandGreen,
              ),
              DashboardLineSeries(
                key: 'despesas',
                label: 'Despesas',
                color: t.posDanger,
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
          points: fluxoDiario,
          labelKey: 'data',
        ),
      ),
      dashboardChartCard(
        context: context,
        title: 'Despesas por categoria',
        child: dashboardPieChart(
          context: context,
          slices: [
            for (var i = 0; i < despesasCategoria.length; i++)
              DashboardPieSlice(
                label: DashboardDataUtils.text(despesasCategoria[i]['categoria']),
                value:
                    (despesasCategoria[i]['total'] as num?)?.toDouble() ?? 0,
                color: _palette(t)[i % _palette(t).length],
              ),
          ],
        ),
      ),
      dashboardChartCard(
        context: context,
        title: 'Recebimentos',
        child: dashboardPieChart(
          context: context,
          slices: [
            for (var i = 0; i < recebimentos.length; i++)
              DashboardPieSlice(
                label: DashboardDataUtils.text(recebimentos[i]['categoria']),
                value: (recebimentos[i]['total'] as num?)?.toDouble() ?? 0,
                color: _palette(t)[i % _palette(t).length],
              ),
          ],
        ),
      ),
      dashboardChartCard(
        context: context,
        title: 'Receita por forma de pagamento',
        child: dashboardBarChart(
          context: context,
          points: metodosPagamento,
          valueKey: 'total',
          labelKey: 'metodo',
          color: t.brandGreen,
        ),
      ),
    ];
  }

  static List<Color> _palette(dynamic t) => [
        t.posDanger,
        t.posWarning,
        t.brandBlue,
        t.brandGreen,
        t.textSecondary,
      ];
}
