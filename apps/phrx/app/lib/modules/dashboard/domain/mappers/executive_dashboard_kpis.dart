import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../shared/widgets/dashboard/enterprise_kpi_card.dart';
import '../../../finance/domain/finance_metrics_keys.dart';
import '../utils/dashboard_data_utils.dart';

abstract final class ExecutiveDashboardKpis {
  ExecutiveDashboardKpis._();

  static List<EnterpriseKpiCard> build(
    BuildContext context,
    Map<String, dynamic>? kpis,
  ) {
    if (kpis == null) return const [];

    final margem = _asDouble(kpis[FinanceMetricsKeys.margem]);
    final crescimento = _asDouble(kpis['crescimento']);
    final criticos = _asDouble(kpis['produtosCriticos']);

    return [
      // Primários (layout enterprise)
      EnterpriseKpiCard(
        title: 'Receita total',
        value: DashboardDataUtils.kpi(kpis, FinanceMetricsKeys.faturamento),
        unit: 'MZN',
        icon: Icons.payments_outlined,
        trend: EnterpriseKpiTrend.positive,
        onTap: () => context.go(AppRoutePaths.financeRevenue),
      ),
      EnterpriseKpiCard(
        title: 'Lucro',
        value: DashboardDataUtils.kpi(kpis, FinanceMetricsKeys.lucroLiquido),
        unit: 'MZN',
        icon: Icons.trending_up,
        trend: EnterpriseKpiTrend.positive,
        onTap: () => context.go(AppRoutePaths.financeExpenses),
      ),
      EnterpriseKpiCard(
        title: 'Saldo de caixa',
        value: DashboardDataUtils.kpi(kpis, FinanceMetricsKeys.saldoAtual),
        unit: 'MZN',
        icon: Icons.account_balance_wallet_outlined,
        trend: EnterpriseKpiTrend.neutral,
        onTap: () => context.go(AppRoutePaths.financeCashflow),
      ),
      EnterpriseKpiCard(
        title: 'Produtos críticos',
        value: DashboardDataUtils.kpi(kpis, 'produtosCriticos'),
        icon: Icons.warning_amber_outlined,
        trend: criticos > 0
            ? EnterpriseKpiTrend.negative
            : EnterpriseKpiTrend.neutral,
        onTap: () => context.go(AppRoutePaths.pharmacyStock),
      ),
      // Secundários
      EnterpriseKpiCard(
        title: 'Margem de lucro',
        value: DashboardDataUtils.kpi(kpis, FinanceMetricsKeys.margem),
        unit: '%',
        icon: Icons.donut_large_outlined,
        trend: margem >= 0
            ? EnterpriseKpiTrend.positive
            : EnterpriseKpiTrend.negative,
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
        title: 'Crescimento',
        value: DashboardDataUtils.kpi(kpis, 'crescimento'),
        unit: kpis['crescimento'] == null ? null : '%',
        icon: Icons.show_chart,
        trend: crescimento > 0
            ? EnterpriseKpiTrend.positive
            : crescimento < 0
                ? EnterpriseKpiTrend.negative
                : EnterpriseKpiTrend.neutral,
      ),
    ];
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
