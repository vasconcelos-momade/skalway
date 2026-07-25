import 'package:flutter/material.dart';

import '../../../../shared/widgets/cards/enterprise_kpi_grid.dart';

/// Secção de KPIs do dashboard — apenas indicadores essenciais (máx. 6).
class DashboardKpiSection extends StatelessWidget {
  const DashboardKpiSection({
    super.key,
    required this.primaryKpis,
  });

  final List<EnterpriseStatCard> primaryKpis;

  @override
  Widget build(BuildContext context) {
    if (primaryKpis.isEmpty) return const SizedBox.shrink();

    return EnterpriseKpiGrid(
      cards: primaryKpis,
      useDesktopRowWhenSingleLine: primaryKpis.length <= 6,
    );
  }
}
