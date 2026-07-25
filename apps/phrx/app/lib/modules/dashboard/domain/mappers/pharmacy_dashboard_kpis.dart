import 'package:flutter/material.dart';

import '../../../../shared/widgets/cards/enterprise_kpi_grid.dart';
import '../utils/dashboard_data_utils.dart';

abstract final class PharmacyDashboardKpis {
  PharmacyDashboardKpis._();

  static List<EnterpriseStatCard> primary(Map<String, dynamic>? kpis) {
    if (kpis == null) return const [];
    final semStock = _asInt(kpis['produtosSemStock']);
    final abaixoMinimo = _asInt(kpis['produtosAbaixoMinimo']);
    final proximas = _asInt(kpis['produtosProximosValidade']);
    final alertas = _asInt(kpis['alertasSanitarios']);

    return [
      dashboardKpiCard(
        title: 'Produtos',
        value: DashboardDataUtils.kpi(kpis, 'produtosCadastrados'),
        icon: Icons.medication_outlined,
        accent: StatCardAccent.info,
      ),
      dashboardKpiCard(
        title: 'Valor do stock',
        value: '${DashboardDataUtils.kpi(kpis, 'valorTotalStock')} MZN',
        icon: Icons.payments_outlined,
        accent: StatCardAccent.positive,
      ),
      dashboardKpiCard(
        title: 'Produtos sem stock',
        value: DashboardDataUtils.kpi(kpis, 'produtosSemStock'),
        icon: Icons.inventory_2_outlined,
        accent: semStock > 0 ? StatCardAccent.warning : StatCardAccent.neutral,
      ),
      dashboardKpiCard(
        title: 'Abaixo do mínimo',
        value: DashboardDataUtils.kpi(kpis, 'produtosAbaixoMinimo'),
        icon: Icons.vertical_align_bottom_outlined,
        accent: abaixoMinimo > 0 ? StatCardAccent.warning : StatCardAccent.neutral,
      ),
      dashboardKpiCard(
        title: 'Próximas validades',
        value: DashboardDataUtils.kpi(kpis, 'produtosProximosValidade'),
        icon: Icons.event_busy,
        accent: proximas > 0 ? StatCardAccent.warning : StatCardAccent.neutral,
      ),
      dashboardKpiCard(
        title: 'Alertas sanitários',
        value: DashboardDataUtils.kpi(kpis, 'alertasSanitarios'),
        icon: Icons.health_and_safety_outlined,
        accent: alertas > 0 ? StatCardAccent.danger : StatCardAccent.neutral,
      ),
    ];
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
