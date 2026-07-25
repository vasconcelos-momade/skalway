import 'package:flutter/material.dart';

import '../../../../../../core/theme/design_tokens.dart';
import '../../../../../../core/theme/extensions.dart';

/// Secção de regulação com ícones de confirmação (✓ / ✗).
class RegulationCard extends StatelessWidget {
  const RegulationCard({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<RegulationItem> items;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: s.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.erpSectionTitle.copyWith(
              color: t.textPrimary,
            ),
          ),
          SizedBox(height: s.sm),
          Material(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(t.radiusMd),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: t.border.withValues(alpha: 0.35)),
                  _RegulationRow(item: items[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RegulationItem {
  const RegulationItem({required this.label, required this.enabled});

  final String label;
  final bool enabled;
}

class _RegulationRow extends StatelessWidget {
  const _RegulationRow({required this.item});

  final RegulationItem item;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final color = item.enabled ? t.brandGreen : t.textMuted;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: s.md, vertical: s.sm),
      child: Row(
        children: [
          Icon(
            item.enabled ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 20,
            color: color,
          ),
          SizedBox(width: s.sm),
          Expanded(
            child: Text(
              item.label,
              style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                    color: t.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
