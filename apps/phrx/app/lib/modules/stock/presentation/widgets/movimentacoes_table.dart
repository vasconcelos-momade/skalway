import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/tables/table_typography.dart';
import '../../domain/entities/movimentacao.dart';

class MovimentacoesTable extends StatelessWidget {
  const MovimentacoesTable({super.key, required this.items});

  final List<Movimentacao> items;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final textTheme = Theme.of(context).textTheme;

    return EnterpriseDataTable(
      columns: [
        DataColumn(label: TableTypography.headerLabel(context, 'Data')),
        DataColumn(label: TableTypography.headerLabel(context, 'Tipo')),
        DataColumn(label: TableTypography.headerLabel(context, 'Produto')),
        DataColumn(label: TableTypography.headerLabel(context, 'Lote')),
        DataColumn(label: TableTypography.headerLabel(context, 'Qtd')),
        DataColumn(label: TableTypography.headerLabel(context, 'Stock')),
        DataColumn(label: TableTypography.headerLabel(context, 'Origem')),
        DataColumn(label: TableTypography.headerLabel(context, 'Documento')),
        DataColumn(label: TableTypography.headerLabel(context, 'Utilizador')),
      ],
      rowCount: items.length,
      rowBuilder: (context, index) {
        final item = items[index];
        final tipoColor = _tipoColor(t, item.tipo);
        final produtoNome = item.produto?.nome ?? '—';
        final barcode = item.produto?.barcode;
        final produtoLabel = barcode == null || barcode.isEmpty
            ? produtoNome
            : '$produtoNome · $barcode';

        return DataRow(
          cells: [
            DataCell(
              TableTypography.cellText(
                context,
                _formatDateTime(item.createdAt),
              ),
            ),
            DataCell(
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.sm,
                  vertical: context.spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: tipoColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: tipoColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  item.tipoLabel,
                  style: textTheme.erpTableSecondary.copyWith(color: tipoColor),
                ),
              ),
            ),
            DataCell(TableTypography.cellText(context, produtoLabel)),
            DataCell(
              TableTypography.cellText(
                context,
                item.lote?.numeroLote ?? '—',
              ),
            ),
            DataCell(
              TableTypography.cellText(
                context,
                _formatQty(item.quantidade),
                style: TableTypography.primary(context),
              ),
            ),
            DataCell(
              TableTypography.cellText(
                context,
                '${_formatQty(item.estoqueAnterior)} → ${_formatQty(item.estoqueFinal)}',
                muted: true,
              ),
            ),
            DataCell(TableTypography.cellText(context, item.origemLabel)),
            DataCell(
              TableTypography.cellText(
                context,
                item.documentoReferencia ?? '—',
                muted: true,
              ),
            ),
            DataCell(
              TableTypography.cellText(context, item.user?.nome ?? '—'),
            ),
          ],
        );
      },
    );
  }

  Color _tipoColor(PharmaTokens t, MovimentacaoTipo? tipo) {
    return switch (tipo) {
      MovimentacaoTipo.entrada => t.brandGreen,
      MovimentacaoTipo.compra => t.brandGreen,
      MovimentacaoTipo.saida => t.posDanger,
      MovimentacaoTipo.ajuste => t.brandBlue,
      MovimentacaoTipo.devolucao => t.posWarning,
      MovimentacaoTipo.quarentena => t.posWarning,
      MovimentacaoTipo.incineracao => t.textMuted,
      null => t.textMuted,
    };
  }

  String _formatQty(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
