import 'package:flutter/material.dart';

import '../../../../shared/widgets/cards/enterprise_kpi_grid.dart';
import '../utils/dashboard_data_utils.dart';

abstract final class ExecutiveDashboardKpis {
  ExecutiveDashboardKpis._();

  static List<EnterpriseStatCard> primary(Map<String, dynamic>? kpis) {
    if (kpis == null) return const [];
    final criticos = _asInt(kpis['produtosCriticos']);
    final proximas = _asInt(kpis['produtosProximosValidade']);

    return [
      dashboardKpiCard(
        title: 'Receita hoje',
        value: '${DashboardDataUtils.kpi(kpis, 'receitaHoje')} MZN',
        icon: Icons.payments_outlined,
        accent: StatCardAccent.positive,
      ),
      dashboardKpiCard(
        title: 'Receita do mês',
        value: '${DashboardDataUtils.kpi(kpis, 'receitaMes')} MZN',
        icon: Icons.calendar_month_outlined,
        accent: StatCardAccent.positive,
      ),
      dashboardKpiCard(
        title: 'Lucro líquido',
        value: '${DashboardDataUtils.kpi(kpis, 'lucroLiquido')} MZN',
        icon: Icons.trending_up,
        accent: StatCardAccent.positive,
      ),
      dashboardKpiCard(
        title: 'Produtos vendidos',
        value: DashboardDataUtils.kpi(kpis, 'produtosVendidos'),
        icon: Icons.shopping_bag_outlined,
        accent: StatCardAccent.info,
      ),
      dashboardKpiCard(
        title: 'Stock crítico',
        value: DashboardDataUtils.kpi(kpis, 'produtosCriticos'),
        icon: Icons.inventory_2_outlined,
        accent: criticos > 0 ? StatCardAccent.danger : StatCardAccent.neutral,
      ),
      dashboardKpiCard(
        title: 'Próximas validades',
        value: DashboardDataUtils.kpi(kpis, 'produtosProximosValidade'),
        icon: Icons.warning_amber_outlined,
        accent: proximas > 0 ? StatCardAccent.warning : StatCardAccent.neutral,
      ),
    ];
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
