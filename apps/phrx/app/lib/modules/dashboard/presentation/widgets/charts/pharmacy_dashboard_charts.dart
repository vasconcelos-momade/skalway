import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../dashboard_widgets.dart';

/// Gráficos do painel farmácia (MVP).
abstract final class PharmacyDashboardCharts {
  PharmacyDashboardCharts._();

  static List<Widget> build(BuildContext context, Map<String, dynamic>? charts) {
    final t = context.pharmaTokens;
    final validades = DashboardDataUtils.map(charts?['validades']) ?? const {};
    final fefo = DashboardDataUtils.map(charts?['fefo']) ?? const {};

    return [
      dashboardChartCard(
        context: context,
        title: 'Validades por prazo',
        child: dashboardIndexedBarChart(
          context: context,
          labels: const ['Exp.', '30d', '60d'],
          values: [
            (validades['lotesExpirados'] as num?)?.toDouble() ?? 0,
            (validades['expiramEm30Dias'] as num?)?.toDouble() ?? 0,
            (validades['expiramEm60Dias'] as num?)?.toDouble() ?? 0,
          ],
          barColors: [t.posDanger, t.posWarning, t.brandBlue],
          barWidth: 28,
        ),
      ),
      dashboardChartCard(
        context: context,
        title: 'Distribuição FEFO',
        child: dashboardPieChart(
          context: context,
          slices: [
            DashboardPieSlice(
              label: 'FEFO',
              value: (fefo['produtosForaFefo'] as num?)?.toDouble() ?? 0,
              color: t.posDanger,
            ),
            DashboardPieSlice(
              label: 'Exp.',
              value: (fefo['lotesExpirados'] as num?)?.toDouble() ?? 0,
              color: t.posWarning,
            ),
            DashboardPieSlice(
              label: 'Bloq.',
              value: (fefo['lotesBloqueados'] as num?)?.toDouble() ?? 0,
              color: t.brandBlue,
            ),
            DashboardPieSlice(
              label: 'Alert.',
              value: (fefo['alertasFefo'] as num?)?.toDouble() ?? 0,
              color: t.brandGreen,
            ),
          ],
        ),
      ),
    ];
  }
}
