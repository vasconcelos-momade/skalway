import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';

class InvoiceStatusBadge extends StatelessWidget {
  const InvoiceStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final normalized = status.toUpperCase();
    final (fg, bg) = switch (normalized) {
      'PAGA' => (t.brandGreen, t.brandGreen.withValues(alpha: 0.12)),
      'ANULADA' => (t.posDanger, t.posDanger.withValues(alpha: 0.12)),
      'PARCIAL' => (t.posWarning, t.posWarning.withValues(alpha: 0.14)),
      _ => (t.brandBlue, t.brandBlue.withValues(alpha: 0.12)),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs + 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(t.radius3xl),
      ),
      child: Text(
        normalized,
        style: Theme.of(context).textTheme.erpOverline.copyWith(color: fg),
      ),
    );
  }
}

class MetaChip extends StatelessWidget {
  const MetaChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs + 2),
      decoration: BoxDecoration(
        color: t.bgSecondary.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(t.radius3xl),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.erpOverline.copyWith(color: t.textSecondary),
      ),
    );
  }
}
