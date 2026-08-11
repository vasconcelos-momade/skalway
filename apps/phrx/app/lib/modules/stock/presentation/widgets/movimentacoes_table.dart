import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/tables/enterprise_table_cells.dart';
import '../../domain/entities/movimentacao.dart';

class MovimentacoesTable extends StatelessWidget {
  const MovimentacoesTable({super.key, required this.items});

  final List<Movimentacao> items;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;

    return EnterpriseDataTable(
      status: items.isEmpty
          ? EnterpriseTableStatus.empty
          : EnterpriseTableStatus.data,
      emptyTitle: 'Nenhum resultado encontrado',
      emptyMessage: 'Nenhum resultado encontrado',
      columns: [
        enterpriseDataColumn(context, 'Data'),
        enterpriseDataColumn(context, 'Tipo'),
        enterpriseDataColumn(context, 'Produto'),
        enterpriseDataColumn(context, 'Lote'),
        enterpriseDataColumn(context, 'Qtd', numeric: true),
        enterpriseDataColumn(context, 'Stock'),
        enterpriseDataColumn(context, 'Origem'),
        enterpriseDataColumn(context, 'Documento'),
        enterpriseDataColumn(context, 'Utilizador'),
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
            DataCell(TableMetadataCell(_formatDateTime(item.createdAt))),
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
                child: TableStatusCell(
                  label: item.tipoLabel,
                  color: tipoColor,
                  showDot: false,
                ),
              ),
            ),
            DataCell(TablePrimaryCell(produtoLabel)),
            DataCell(TableMetadataCell(item.lote?.numeroLote)),
            DataCell(TableNumericCell(_formatQty(item.quantidade))),
            DataCell(
              TableMetadataCell(
                '${_formatQty(item.estoqueAnterior)} → ${_formatQty(item.estoqueFinal)}',
              ),
            ),
            DataCell(TableSecondaryCell(item.origemLabel)),
            DataCell(TableMetadataCell(item.documentoReferencia)),
            DataCell(TableSecondaryCell(item.user?.nome ?? '—')),
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
