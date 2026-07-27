import 'package:flutter/material.dart';

import '../../../../shared/widgets/dashboard/enterprise_kpi_card.dart';
import '../utils/dashboard_data_utils.dart';

abstract final class StockDashboardKpis {
  StockDashboardKpis._();

  static List<EnterpriseKpiCard> primary(Map<String, dynamic>? kpis) {
    if (kpis == null) return const [];
    return [
      EnterpriseKpiCard(
        title: 'Stock disponível',
        value: DashboardDataUtils.kpi(kpis, 'stockDisponivel'),
        icon: Icons.inventory_2_outlined,
        trend: EnterpriseKpiTrend.positive,
      ),
      EnterpriseKpiCard(
        title: 'Valor stock',
        value: '${DashboardDataUtils.kpi(kpis, 'valorTotalStock')} MZN',
        icon: Icons.payments_outlined,
      ),
      EnterpriseKpiCard(
        title: 'Críticos',
        value: DashboardDataUtils.kpi(kpis, 'produtosCriticos'),
        icon: Icons.warning_amber_outlined,
        trend: EnterpriseKpiTrend.negative,
      ),
      EnterpriseKpiCard(
        title: 'Sem stock',
        value: DashboardDataUtils.kpi(kpis, 'produtosSemStock'),
        icon: Icons.remove_shopping_cart_outlined,
        trend: EnterpriseKpiTrend.negative,
      ),
      EnterpriseKpiCard(
        title: 'Lotes activos',
        value: DashboardDataUtils.kpi(kpis, 'lotesAtivos'),
        icon: Icons.layers_outlined,
      ),
    ];
  }

  static List<EnterpriseKpiCard> secondary(Map<String, dynamic>? kpis) {
    if (kpis == null) return const [];
    return [
      EnterpriseKpiCard(
        title: 'Stock total',
        value: DashboardDataUtils.kpi(kpis, 'stockTotal'),
        icon: Icons.inventory_outlined,
      ),
      EnterpriseKpiCard(
        title: 'Reservado',
        value: DashboardDataUtils.kpi(kpis, 'stockReservado'),
        icon: Icons.lock_clock_outlined,
      ),
      EnterpriseKpiCard(
        title: 'Inventários',
        value: DashboardDataUtils.kpi(kpis, 'inventariosAbertos'),
        icon: Icons.fact_check_outlined,
      ),
      EnterpriseKpiCard(
        title: 'Sugestões compra',
        value: DashboardDataUtils.kpi(kpis, 'sugestoesCompra'),
        icon: Icons.shopping_cart_outlined,
      ),
      EnterpriseKpiCard(
        title: 'Incinerações',
        value: DashboardDataUtils.kpi(kpis, 'incineracoes'),
        icon: Icons.delete_sweep_outlined,
        trend: EnterpriseKpiTrend.negative,
      ),
      EnterpriseKpiCard(
        title: 'Ajustes stock',
        value: DashboardDataUtils.kpi(kpis, 'ajustesStock'),
        icon: Icons.tune_outlined,
      ),
      EnterpriseKpiCard(
        title: 'Alertas operac.',
        value: DashboardDataUtils.kpi(kpis, 'alertasOperacionais'),
        icon: Icons.crisis_alert_outlined,
        trend: EnterpriseKpiTrend.negative,
      ),
    ];
  }
}
