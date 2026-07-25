import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../core/theme/pharma_surface.dart';
import '../../domain/utils/dashboard_data_utils.dart';

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

    final criticos = asInt(kpis?['produtosCriticos']);
    final proximas = asInt(kpis?['produtosProximosValidade']);
    final expirados = asInt(kpis?['lotesExpirados']);
    final contasReceber = DashboardDataUtils.kpi(kpis, 'contasReceber');
    final contasReceberValue = (kpis?['contasReceber'] as num?)?.toDouble() ?? 0;

    return DashboardAlertsPanel(
      items: [
        DashboardAlertItem(
          label: 'Produtos com stock crítico',
          value: criticos > 0 ? '$criticos' : 'OK',
          critical: criticos > 0,
        ),
        DashboardAlertItem(
          label: 'Produtos a vencer',
          value: proximas > 0 ? '$proximas' : 'OK',
          attention: proximas > 0,
        ),
        DashboardAlertItem(
          label: 'Contas a receber',
          value: contasReceberValue > 0 ? '$contasReceber MZN' : 'OK',
          attention: contasReceberValue > 0,
        ),
        DashboardAlertItem(
          label: 'Lotes expirados',
          value: expirados > 0 ? '$expirados' : 'OK',
          critical: expirados > 0,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return PharmaSurface(
      padding: t.density.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'PAINEL DE ALERTAS',
            style: Theme.of(context).textTheme.erpOverline.copyWith(
                  color: t.textMuted,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(color: t.border.withValues(alpha: 0.35)),
            _AlertRow(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.item});

  final DashboardAlertItem item;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final color = item.critical
        ? t.posDanger
        : item.attention
            ? t.posWarning
            : t.brandGreen;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            item.critical
                ? Icons.error_outline_rounded
                : item.attention
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              item.label,
              style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                    color: t.textPrimary,
                  ),
            ),
          ),
          Text(
            item.value,
            style: Theme.of(context).textTheme.erpLabel.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
