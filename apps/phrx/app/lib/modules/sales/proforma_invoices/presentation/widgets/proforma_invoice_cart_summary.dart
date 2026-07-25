import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../pdv/presentation/widgets/pdv_catalog_utils.dart';

class ProformaInvoiceCartSummary extends StatelessWidget {
  const ProformaInvoiceCartSummary({
    super.key,
    required this.itemCount,
    required this.subtotal,
    required this.descontoTotal,
    required this.ivaTotal,
    required this.total,
    this.action,
  });

  final int itemCount;
  final double subtotal;
  final double descontoTotal;
  final double ivaTotal;
  final double total;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(s.md),
      decoration: BoxDecoration(
        color: t.card,
        border: Border(top: BorderSide(color: t.border.withValues(alpha: 0.45))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row(
            context,
            label: 'Itens',
            value: '$itemCount',
          ),
          SizedBox(height: s.xs),
          _row(context, label: 'Subtotal', value: pdvFormatMoney(subtotal)),
          SizedBox(height: s.xs),
          _row(
            context,
            label: 'Descontos',
            value: '- ${pdvFormatMoney(descontoTotal)}',
            valueColor: t.posDanger,
          ),
          SizedBox(height: s.xs),
          _row(context, label: 'IVA', value: pdvFormatMoney(ivaTotal)),
          SizedBox(height: s.sm),
          Container(
            padding: EdgeInsets.all(s.sm),
            decoration: BoxDecoration(
              color: t.brandGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(t.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: textTheme.erpCardTitle.copyWith(color: t.textPrimary),
                ),
                Text(
                  pdvFormatMoney(total),
                  style: textTheme.erpCardTitle.copyWith(color: t.brandGreen),
                ),
              ],
            ),
          ),
          if (action != null) ...[
            SizedBox(height: s.md),
            action!,
          ],
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final t = context.pharmaTokens;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.erpBodySecondary.copyWith(color: t.textSecondary),
        ),
        Text(
          value,
          style: textTheme.erpLabel.copyWith(color: valueColor ?? t.textPrimary),
        ),
      ],
    );
  }
}
