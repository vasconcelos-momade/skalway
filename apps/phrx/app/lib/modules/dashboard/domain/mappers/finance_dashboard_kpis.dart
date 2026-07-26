import 'package:flutter/material.dart';

import '../../../../shared/widgets/cards/enterprise_kpi_grid.dart';
import '../utils/dashboard_data_utils.dart';

abstract final class FinanceDashboardKpis {
  FinanceDashboardKpis._();

  static List<EnterpriseStatCard> cashOperation(Map<String, dynamic>? kpis) {
    if (kpis == null) return const [];
    return [
      dashboardKpiCard(
        title: 'Saldo inicial',
        value: '${DashboardDataUtils.kpi(kpis, 'saldoInicial')} MZN',
        icon: Icons.playlist_add_check_circle_outlined,
        accent: StatCardAccent.neutral,
      ),
      dashboardKpiCard(
        title: 'Vendas',
        value: '${DashboardDataUtils.kpi(kpis, 'vendas')} MZN',
        icon: Icons.point_of_sale_outlined,
        accent: StatCardAccent.positive,
      ),
      dashboardKpiCard(
        title: 'Suprimentos',
        value: '${DashboardDataUtils.kpi(kpis, 'suprimentos')} MZN',
        icon: Icons.add_circle_outline,
        accent: StatCardAccent.positive,
      ),
      dashboardKpiCard(
        title: 'Despesas',
        value: '${DashboardDataUtils.kpi(kpis, 'despesas')} MZN',
        icon: Icons.remove_circle_outline,
        accent: StatCardAccent.warning,
      ),
      dashboardKpiCard(
        title: 'Sangrias',
        value: '${DashboardDataUtils.kpi(kpis, 'sangrias')} MZN',
        icon: Icons.savings_outlined,
        accent: StatCardAccent.warning,
      ),
      dashboardKpiCard(
        title: 'Estornos',
        value: '${DashboardDataUtils.kpi(kpis, 'estornos')} MZN',
        icon: Icons.settings_backup_restore_outlined,
        accent: StatCardAccent.info,
      ),
      dashboardKpiCard(
        title: 'Saldo final',
        value: '${DashboardDataUtils.kpi(kpis, 'saldoFinal')} MZN',
        icon: Icons.account_balance_wallet,
        accent: StatCardAccent.positive,
      ),
    ];
  }

  static List<EnterpriseStatCard> commercial(Map<String, dynamic>? kpis) {
    if (kpis == null) return const [];
    return [
      dashboardKpiCard(
        title: 'Faturamento / Receita',
        value: '${DashboardDataUtils.kpi(kpis, 'faturamento')} MZN',
        subtitle: 'Receita: ${DashboardDataUtils.kpi(kpis, 'receita')} MZN',
        icon: Icons.trending_up,
        accent: StatCardAccent.info,
      ),
      dashboardKpiCard(
        title: 'N.º de vendas',
        value: DashboardDataUtils.kpi(kpis, 'numVendas'),
        icon: Icons.receipt_long_outlined,
        accent: StatCardAccent.neutral,
      ),
      dashboardKpiCard(
        title: 'Ticket médio',
        value: '${DashboardDataUtils.kpi(kpis, 'ticketMedio')} MZN',
        icon: Icons.sell_outlined,
        accent: StatCardAccent.info,
      ),
      dashboardKpiCard(
        title: 'Lucro bruto',
        value: '${DashboardDataUtils.kpi(kpis, 'lucroBruto')} MZN',
        icon: Icons.percent,
        accent: StatCardAccent.positive,
      ),
    ];
  }
}
