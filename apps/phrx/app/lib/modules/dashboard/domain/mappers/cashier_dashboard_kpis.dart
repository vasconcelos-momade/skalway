import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../shared/widgets/dashboard/enterprise_kpi_card.dart';
import '../utils/dashboard_data_utils.dart';

abstract final class CashierDashboardKpis {
  CashierDashboardKpis._();

  static List<EnterpriseKpiCard> build(
    BuildContext context,
    Map<String, dynamic>? kpis,
  ) {
    if (kpis == null) return const [];

    final aberto = kpis['caixaAberto'] == true;
    final estado = DashboardDataUtils.text(kpis['estadoCaixa']);

    return [
      EnterpriseKpiCard(
        title: 'Vendas do dia',
        value: DashboardDataUtils.kpi(kpis, 'totalVendasDia'),
        unit: 'MZN',
        icon: Icons.payments_outlined,
        trend: EnterpriseKpiTrend.positive,
        onTap: () => context.go(AppRoutePaths.salesInvoices),
      ),
      EnterpriseKpiCard(
        title: 'N.º de vendas',
        value: DashboardDataUtils.kpi(kpis, 'numVendas'),
        icon: Icons.receipt_long_outlined,
        trend: EnterpriseKpiTrend.neutral,
        onTap: () => context.go(AppRoutePaths.salesInvoices),
      ),
      EnterpriseKpiCard(
        title: 'Ticket médio',
        value: DashboardDataUtils.kpi(kpis, 'ticketMedio'),
        unit: 'MZN',
        icon: Icons.sell_outlined,
        trend: EnterpriseKpiTrend.neutral,
      ),
      EnterpriseKpiCard(
        title: 'Valor em caixa',
        value: DashboardDataUtils.kpi(kpis, 'valorEmCaixa'),
        unit: 'MZN',
        icon: Icons.account_balance_wallet_outlined,
        trend: EnterpriseKpiTrend.neutral,
        onTap: () => context.go(AppRoutePaths.financeCashflow),
      ),
      EnterpriseKpiCard(
        title: 'Estado do caixa',
        value: estado,
        icon: aberto
            ? Icons.lock_open_outlined
            : Icons.lock_outline,
        trend: aberto
            ? EnterpriseKpiTrend.positive
            : EnterpriseKpiTrend.negative,
        onTap: () => context.go(AppRoutePaths.pos),
      ),
      EnterpriseKpiCard(
        title: 'Sessões abertas',
        value: DashboardDataUtils.kpi(kpis, 'sessoesAbertas'),
        icon: Icons.point_of_sale_outlined,
        trend: EnterpriseKpiTrend.neutral,
        onTap: () => context.go(AppRoutePaths.pos),
      ),
    ];
  }
}
