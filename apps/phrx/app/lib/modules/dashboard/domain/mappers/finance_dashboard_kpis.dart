import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../shared/widgets/dashboard/enterprise_kpi_card.dart';
import '../../../finance/domain/finance_metrics_keys.dart';
import '../utils/dashboard_data_utils.dart';

abstract final class FinanceDashboardKpis {
  FinanceDashboardKpis._();

  static List<EnterpriseKpiCard> build(
    BuildContext context,
    Map<String, dynamic>? kpis,
  ) {
    if (kpis == null) return const [];

    return [
      EnterpriseKpiCard(
        title: 'Receita',
        value: DashboardDataUtils.kpi(kpis, FinanceMetricsKeys.receita),
        unit: 'MZN',
        icon: Icons.payments_outlined,
        trend: EnterpriseKpiTrend.positive,
        onTap: () => context.go(AppRoutePaths.financeRevenue),
      ),
      EnterpriseKpiCard(
        title: 'Lucro bruto',
        value: DashboardDataUtils.kpi(kpis, FinanceMetricsKeys.lucroBruto),
        unit: 'MZN',
        icon: Icons.stacked_line_chart,
        trend: EnterpriseKpiTrend.positive,
      ),
      EnterpriseKpiCard(
        title: 'Lucro líquido',
        value: DashboardDataUtils.kpi(kpis, FinanceMetricsKeys.lucroLiquido),
        unit: 'MZN',
        icon: Icons.trending_up,
        trend: EnterpriseKpiTrend.positive,
        onTap: () => context.go(AppRoutePaths.financeExpenses),
      ),
      EnterpriseKpiCard(
        title: 'Saldo caixa',
        value: DashboardDataUtils.kpi(kpis, FinanceMetricsKeys.saldoAtual),
        unit: 'MZN',
        icon: Icons.account_balance_wallet_outlined,
        trend: EnterpriseKpiTrend.neutral,
        onTap: () => context.go(AppRoutePaths.financeCashflow),
      ),
      EnterpriseKpiCard(
        title: 'N.º de vendas',
        value: DashboardDataUtils.kpi(kpis, FinanceMetricsKeys.numVendas),
        icon: Icons.receipt_long_outlined,
        trend: EnterpriseKpiTrend.neutral,
        onTap: () => context.go(AppRoutePaths.salesInvoices),
      ),
      EnterpriseKpiCard(
        title: 'Ticket médio',
        value: DashboardDataUtils.kpi(kpis, FinanceMetricsKeys.ticketMedio),
        unit: 'MZN',
        icon: Icons.sell_outlined,
        trend: EnterpriseKpiTrend.neutral,
      ),
      EnterpriseKpiCard(
        title: 'Contas a receber',
        value: DashboardDataUtils.kpi(kpis, 'contasReceber'),
        unit: 'MZN',
        icon: Icons.request_quote_outlined,
        trend: EnterpriseKpiTrend.neutral,
      ),
      EnterpriseKpiCard(
        title: 'Despesas operacionais',
        value: DashboardDataUtils.kpi(kpis, FinanceMetricsKeys.despesas),
        unit: 'MZN',
        icon: Icons.remove_circle_outline,
        trend: EnterpriseKpiTrend.negative,
        onTap: () => context.go(AppRoutePaths.financeExpenses),
      ),
    ];
  }
}
