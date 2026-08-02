import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../dashboard_widgets.dart';

abstract final class CashierDashboardCharts {
  CashierDashboardCharts._();

  static List<Widget> build(BuildContext context, Map<String, dynamic>? charts) {
    final t = context.pharmaTokens;
    final metodos = DashboardDataUtils.list(charts?['metodosPagamento']);
    final resumo = DashboardDataUtils.list(charts?['resumoMovimento']);

    return [
      dashboardChartCard(
        context: context,
        title: 'Formas de pagamento',
        subtitle: 'Distribuição das vendas do dia',
        child: dashboardPieChart(
          context: context,
          slices: [
            for (var i = 0; i < metodos.length; i++)
              DashboardPieSlice(
                label: DashboardDataUtils.text(metodos[i]['metodo']),
                value: (metodos[i]['total'] as num?)?.toDouble() ?? 0,
                color: _palette(t)[i % _palette(t).length],
              ),
          ],
        ),
      ),
      dashboardChartCard(
        context: context,
        title: 'Resumo do movimento',
        subtitle: 'Entradas e saídas do caixa hoje',
        child: dashboardBarChart(
          context: context,
          points: resumo,
          valueKey: 'valor',
          labelKey: 'tipo',
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
