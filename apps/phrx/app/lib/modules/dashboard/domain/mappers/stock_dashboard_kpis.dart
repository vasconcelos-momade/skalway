import 'package:flutter/material.dart';

import '../../../../shared/widgets/cards/enterprise_kpi_grid.dart';
import '../utils/dashboard_data_utils.dart';

abstract final class StockDashboardKpis {
  StockDashboardKpis._();

  static List<EnterpriseStatCard> primary(Map<String, dynamic>? kpis) {
    if (kpis == null) return const [];
    return [
      dashboardKpiCard(
        title: 'Stock disponível',
        value: DashboardDataUtils.kpi(kpis, 'stockDisponivel'),
        icon: Icons.inventory_2_outlined,
        accent: StatCardAccent.positive,
      ),
      dashboardKpiCard(
        title: 'Valor stock',
        value: '${DashboardDataUtils.kpi(kpis, 'valorTotalStock')} MZN',
        icon: Icons.payments_outlined,
      ),
      dashboardKpiCard(
        title: 'Críticos',
        value: DashboardDataUtils.kpi(kpis, 'produtosCriticos'),
        icon: Icons.warning_amber_outlined,
        accent: StatCardAccent.danger,
      ),
      dashboardKpiCard(
        title: 'Sem stock',
        value: DashboardDataUtils.kpi(kpis, 'produtosSemStock'),
        icon: Icons.remove_shopping_cart_outlined,
        accent: StatCardAccent.warning,
      ),
      dashboardKpiCard(
        title: 'Lotes activos',
        value: DashboardDataUtils.kpi(kpis, 'lotesAtivos'),
        icon: Icons.layers_outlined,
      ),
    ];
  }

  static List<EnterpriseStatCard> secondary(Map<String, dynamic>? kpis) {
    if (kpis == null) return const [];
    return [
      dashboardKpiCard(
        title: 'Stock total',
        value: DashboardDataUtils.kpi(kpis, 'stockTotal'),
        icon: Icons.inventory_outlined,
      ),
      dashboardKpiCard(
        title: 'Reservado',
        value: DashboardDataUtils.kpi(kpis, 'stockReservado'),
        icon: Icons.lock_clock_outlined,
      ),
      dashboardKpiCard(
        title: 'Inventários',
        value: DashboardDataUtils.kpi(kpis, 'inventariosAbertos'),
        icon: Icons.fact_check_outlined,
      ),
      dashboardKpiCard(
        title: 'Sugestões compra',
        value: DashboardDataUtils.kpi(kpis, 'sugestoesCompra'),
        icon: Icons.shopping_cart_outlined,
      ),
      dashboardKpiCard(
        title: 'Incinerações',
        value: DashboardDataUtils.kpi(kpis, 'incineracoes'),
        icon: Icons.delete_sweep_outlined,
        accent: StatCardAccent.warning,
      ),
      dashboardKpiCard(
        title: 'Ajustes stock',
        value: DashboardDataUtils.kpi(kpis, 'ajustesStock'),
        icon: Icons.tune_outlined,
      ),
      dashboardKpiCard(
        title: 'Alertas operac.',
        value: DashboardDataUtils.kpi(kpis, 'alertasOperacionais'),
        icon: Icons.crisis_alert_outlined,
        accent: StatCardAccent.danger,
      ),
    ];
  }
}
