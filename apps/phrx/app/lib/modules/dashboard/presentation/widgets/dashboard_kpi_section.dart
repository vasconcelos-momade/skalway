import 'package:flutter/material.dart';

import '../../../../shared/widgets/cards/enterprise_kpi_grid.dart';

/// Secção de KPIs do dashboard — até 8 indicadores (2 linhas de 4 no desktop).
class DashboardKpiSection extends StatelessWidget {
  const DashboardKpiSection({
    super.key,
    required this.kpis,
  });

  final List<Widget> kpis;

  @override
  Widget build(BuildContext context) {
    if (kpis.isEmpty) return const SizedBox.shrink();

    return EnterpriseKpiGrid(
      cards: kpis,
      useDesktopRowWhenSingleLine: kpis.length <= 4,
    );
  }
}
