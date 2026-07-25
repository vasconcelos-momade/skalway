import 'package:flutter/material.dart';

import '../dashboard_charts_section.dart';
import '../dashboard_widgets.dart';

/// Gráficos do painel financeiro (MVP).
abstract final class FinanceDashboardCharts {
  FinanceDashboardCharts._();

  static List<Widget> build(BuildContext context, Map<String, dynamic>? charts) {
    final scheme = Theme.of(context).colorScheme;
    return [
      DashboardChartSlot(
        fullWidth: true,
        child: dashboardChartCard(
          context: context,
          title: 'Fluxo financeiro mensal',
          child: dashboardTrendBarChart(
            context: context,
            points: DashboardDataUtils.list(charts?['fluxoMensal']),
            valueKey: 'saldo',
            labelKey: 'mes',
            color: scheme.secondary,
            allowNegative: true,
          ),
        ),
      ),
      dashboardChartCard(
        context: context,
        title: 'Receitas x despesas',
        child: dashboardDualTrendBarChart(
          context: context,
          points: DashboardDataUtils.list(charts?['receitasDespesas']),
          labelKey: 'data',
        ),
      ),
      dashboardChartCard(
        context: context,
        title: 'Métodos de pagamento',
        child: dashboardBarChart(
          context: context,
          points: DashboardDataUtils.list(charts?['metodosPagamento']),
          valueKey: 'total',
          labelKey: 'metodo',
          color: scheme.tertiary,
        ),
      ),
    ];
  }
}
