import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../shared/widgets/dashboard/enterprise_kpi_card.dart';
import '../utils/dashboard_data_utils.dart';

abstract final class PharmacyDashboardKpis {
  PharmacyDashboardKpis._();

  static List<EnterpriseKpiCard> build(
    BuildContext context,
    Map<String, dynamic>? kpis,
  ) {
    if (kpis == null) return const [];

    final criticos = _asInt(kpis['produtosAbaixoMinimo']);
    final semStock = _asInt(kpis['produtosSemStock']);
    final proximas = _asInt(kpis['produtosProximosValidade']);

    return [
      EnterpriseKpiCard(
        title: 'Produtos cadastrados',
        value: DashboardDataUtils.kpi(kpis, 'produtosCadastrados'),
        icon: Icons.medication_outlined,
        accent: StatCardAccent.info,
        trend: EnterpriseKpiTrend.neutral,
      ),
      EnterpriseKpiCard(
        title: 'Valor em estoque',
        value: DashboardDataUtils.kpi(kpis, 'valorTotalStock'),
        unit: 'MZN',
        icon: Icons.inventory_2_outlined,
        accent: StatCardAccent.positive,
        trend: EnterpriseKpiTrend.neutral,
      ),
      EnterpriseKpiCard(
        title: 'Produtos críticos',
        value: DashboardDataUtils.kpi(kpis, 'produtosAbaixoMinimo'),
        icon: Icons.warning_amber_outlined,
        accent: StatCardAccent.warning,
        trend: criticos > 0
            ? EnterpriseKpiTrend.negative
            : EnterpriseKpiTrend.neutral,
        onTap: () => context.go(AppRoutePaths.pharmacyStock),
      ),
      EnterpriseKpiCard(
        title: 'Sem estoque',
        value: DashboardDataUtils.kpi(kpis, 'produtosSemStock'),
        icon: Icons.remove_shopping_cart_outlined,
        accent: StatCardAccent.danger,
        trend: semStock > 0
            ? EnterpriseKpiTrend.negative
            : EnterpriseKpiTrend.neutral,
        onTap: () => context.go(AppRoutePaths.pharmacyStock),
      ),
      EnterpriseKpiCard(
        title: 'Lotes a vencer',
        value: DashboardDataUtils.kpi(kpis, 'produtosProximosValidade'),
        icon: Icons.event_busy_outlined,
        accent: StatCardAccent.warning,
        trend: proximas > 0
            ? EnterpriseKpiTrend.negative
            : EnterpriseKpiTrend.neutral,
      ),
      EnterpriseKpiCard(
        title: 'Prescrições do dia',
        value: DashboardDataUtils.kpi(kpis, 'prescricoesHoje'),
        icon: Icons.medical_services_outlined,
        accent: StatCardAccent.info,
        trend: EnterpriseKpiTrend.neutral,
      ),
      EnterpriseKpiCard(
        title: 'Vendas hoje',
        value: DashboardDataUtils.kpi(kpis, 'vendasHoje'),
        icon: Icons.point_of_sale_outlined,
        accent: StatCardAccent.positive,
        trend: EnterpriseKpiTrend.positive,
        onTap: () => context.go(AppRoutePaths.salesInvoices),
      ),
      EnterpriseKpiCard(
        title: 'Valor vendido hoje',
        value: DashboardDataUtils.kpi(kpis, 'valorVendidoHoje'),
        unit: 'MZN',
        icon: Icons.payments_outlined,
        accent: StatCardAccent.neutral,
        trend: EnterpriseKpiTrend.positive,
        onTap: () => context.go(AppRoutePaths.salesInvoices),
      ),
    ];
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
