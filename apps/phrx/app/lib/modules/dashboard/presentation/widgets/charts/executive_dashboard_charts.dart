import 'package:flutter/material.dart';

import '../dashboard_widgets.dart';

/// Gráficos do painel executivo (MVP).
abstract final class ExecutiveDashboardCharts {
  ExecutiveDashboardCharts._();

  static List<Widget> build(BuildContext context, Map<String, dynamic>? charts) {
    final scheme = Theme.of(context).colorScheme;
    return [
      dashboardChartCard(
        context: context,
        title: 'Receita mensal',
        child: dashboardTrendBarChart(
          context: context,
          points: DashboardDataUtils.list(charts?['receitaMensal']),
          valueKey: 'total',
          labelKey: 'mes',
          color: scheme.primary,
        ),
      ),
      dashboardChartCard(
        context: context,
        title: 'Vendas por forma de pagamento',
        child: dashboardBarChart(
          context: context,
          points: DashboardDataUtils.list(charts?['metodosPagamento']),
          valueKey: 'total',
          labelKey: 'metodo',
          color: scheme.secondary,
        ),
      ),
    ];
  }
}
