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

    return Container(
      padding: EdgeInsets.only(top: s.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row(context, label: 'Subtotal', value: pdvFormatMoney(subtotal)),
          SizedBox(height: s.xs),
          _row(
            context,
            label: 'Desconto',
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
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL',
                  style: Theme.of(
                    context,
                  ).textTheme.erpLabel.copyWith(color: t.brandGreen),
                ),
                Text(
                  pdvFormatMoney(total),
                  style: Theme.of(
                    context,
                  ).textTheme.erpAppBarTitle.copyWith(color: t.brandGreen),
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
