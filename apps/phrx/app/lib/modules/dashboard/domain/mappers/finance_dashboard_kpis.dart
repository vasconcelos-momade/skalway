import 'package:flutter/material.dart';

import '../../../../shared/widgets/cards/enterprise_kpi_grid.dart';
import '../utils/dashboard_data_utils.dart';

abstract final class FinanceDashboardKpis {
  FinanceDashboardKpis._();

  static List<EnterpriseStatCard> primary(Map<String, dynamic>? kpis) {
    if (kpis == null) return const [];
    return [
      dashboardKpiCard(
        title: 'Receita',
        value: '${DashboardDataUtils.kpi(kpis, 'receita')} MZN',
        icon: Icons.trending_up,
        accent: StatCardAccent.positive,
      ),
      dashboardKpiCard(
        title: 'Saídas',
        value: '${DashboardDataUtils.kpi(kpis, 'saidas')} MZN',
        icon: Icons.remove_circle_outline,
        accent: StatCardAccent.warning,
      ),
      dashboardKpiCard(
        title: 'Suprimentos',
        value: '${DashboardDataUtils.kpi(kpis, 'suprimentos')} MZN',
        icon: Icons.add_circle_outline,
        accent: StatCardAccent.positive,
      ),
      dashboardKpiCard(
        title: 'Sangria',
        value: '${DashboardDataUtils.kpi(kpis, 'sangrias')} MZN',
        icon: Icons.arrow_upward,
        accent: StatCardAccent.warning,
      ),
      dashboardKpiCard(
        title: 'Lucro',
        value: '${DashboardDataUtils.kpi(kpis, 'lucro')} MZN',
        icon: Icons.percent,
        accent: StatCardAccent.positive,
      ),
      dashboardKpiCard(
        title: 'Saldo em caixa',
        value: '${DashboardDataUtils.kpi(kpis, 'saldoAtual')} MZN',
        icon: Icons.account_balance_wallet,
        accent: StatCardAccent.positive,
      ),
      dashboardKpiCard(
        title: 'Contas a receber',
        value: '${DashboardDataUtils.kpi(kpis, 'contasReceber')} MZN',
        icon: Icons.call_received,
        accent: StatCardAccent.info,
      ),
      dashboardKpiCard(
        title: 'Contas a pagar',
        value: '${DashboardDataUtils.kpi(kpis, 'contasPagar')} MZN',
        icon: Icons.call_made,
        accent: StatCardAccent.warning,
      ),
    ];
  }
}
