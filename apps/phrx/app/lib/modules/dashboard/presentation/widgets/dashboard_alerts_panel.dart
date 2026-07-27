import 'package:flutter/material.dart';

import '../../../../core/theme/extensions.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/utils/dashboard_data_utils.dart';

import '../../../../shared/widgets/dashboard/enterprise_alert_card.dart';
import '../../../../shared/widgets/dashboard/enterprise_section.dart';

class DashboardAlertItem {
  const DashboardAlertItem({
    required this.label,
    required this.value,
    this.critical = false,
    this.attention = false,
  });

  final String label;
  final String value;
  final bool critical;
  final bool attention;
}

/// Painel compacto de alertas do dashboard executivo.
class DashboardAlertsPanel extends StatelessWidget {
  const DashboardAlertsPanel({
    super.key,
    required this.items,
  });

  final List<DashboardAlertItem> items;

  factory DashboardAlertsPanel.fromExecutiveKpis(Map<String, dynamic>? kpis) {
    int asInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double asDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    final criticos = asInt(kpis?['produtosCriticos']);
    final proximas = asInt(kpis?['produtosProximosValidade']);
    final contasPagar = asDouble(kpis?['contasPagar']);
    final alertasFiscais = asInt(kpis?['pendenciasFiscais']);

    return DashboardAlertsPanel(
      items: [
        DashboardAlertItem(
          label: 'Produtos críticos',
          value: criticos > 0 ? '$criticos' : 'OK',
          critical: criticos > 0,
        ),
        DashboardAlertItem(
          label: 'Lotes próximos do vencimento',
          value: proximas > 0 ? '$proximas' : 'OK',
          attention: proximas > 0,
        ),
        DashboardAlertItem(
          label: 'Contas vencidas',
          value: contasPagar > 0
              ? '${DashboardDataUtils.kpi(kpis, 'contasPagar')} MZN'
              : 'OK',
          critical: contasPagar > 0,
        ),
        DashboardAlertItem(
          label: 'Pendências fiscais',
          value: alertasFiscais > 0 ? '$alertasFiscais' : 'OK',
          attention: alertasFiscais > 0,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeItems = items.where((i) => i.critical || i.attention).toList();

    if (activeItems.isEmpty) {
      return EnterpriseSection(
        title: 'Alertas',
        child: EnterpriseAlertCard(
          title: 'Tudo OK',
          description: 'Não há alertas críticos no momento.',
          severity: EnterpriseAlertSeverity.success,
        ),
      );
    }

    return EnterpriseSection(
      title: 'Alertas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < activeItems.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            EnterpriseAlertCard(
              title: activeItems[i].label,
              description: activeItems[i].value,
              severity: activeItems[i].critical
                  ? EnterpriseAlertSeverity.error
                  : EnterpriseAlertSeverity.warning,
            ),
          ],
        ],
      ),
    );
  }
}
