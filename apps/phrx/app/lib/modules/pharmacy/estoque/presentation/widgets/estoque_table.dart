import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../core/utils/lote_stock_utils.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../domain/entities/estoque_item.dart';
import 'estoque_actions_menu.dart';
import 'estoque_badges.dart';

class EstoqueTable extends StatelessWidget {
  const EstoqueTable({
    super.key,
    required this.items,
    required this.actionLoteId,
    this.fornecedores = const [],
  });

  final List<EstoqueItem> items;
  final String? actionLoteId;
  final List<({String id, String nome})> fornecedores;

  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static const _columnLabels = [
    'Produto',
    'Lote',
    'Validade',
    'P. compra',
    'P. venda',
    'Stock',
    'Quarentena',
    'Incineração',
    'Ações',
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final textTheme = Theme.of(context).textTheme;

    return EnterpriseDataTable(
      adaptive: false,
      showCheckboxColumn: false,
      dataRowMinHeight: 64,
      dataRowMaxHeight: 88,
      columnSpacing: s.md,
      columns: [
        for (var i = 0; i < _columnLabels.length; i++)
          DataColumn(
            numeric: i >= 3 && i <= 7,
            label: Text(
              _columnLabels[i].toUpperCase(),
              style: textTheme.erpTableHeader.copyWith(color: t.textMuted),
            ),
          ),
      ],
      rowCount: items.length,
      rowBuilder: (context, index) {
        final item = items[index];
        return DataRow(
          cells: [
            DataCell(_produtoCell(context, item)),
            DataCell(Text(item.numeroLote)),
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_formatDate(item.dataValidade)),
                  EstoqueBadges.validade(context, item),
                ],
              ),
            ),
            DataCell(Text(item.precoCompra.toStringAsFixed(2))),
            DataCell(Text(item.precoVenda?.toStringAsFixed(2) ?? '—')),
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(LoteStockUtils.formatDisponivelFromNum(item.quantidadeDisponivel)),
                  EstoqueBadges.stock(context, item),
                ],
              ),
            ),
            DataCell(
              Text(
                LoteStockUtils.formatDisponivelFromNum(item.quantidadeQuarentena),
              ),
            ),
            DataCell(
              Text(
                LoteStockUtils.formatDisponivelFromNum(item.quantidadeIncinerada),
              ),
            ),
            DataCell(
              EstoqueActionsMenu(
                item: item,
                isBusy: actionLoteId == item.id,
                fornecedores: fornecedores,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _produtoCell(BuildContext context, EstoqueItem item) {
    final t = context.pharmaTokens;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.produtoDisplayLabel,
          style: textTheme.erpTablePrimary.copyWith(color: t.textPrimary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if ((item.produtoNomeGenerico ?? '').isNotEmpty)
          Text(
            item.produtoNomeGenerico!,
            style: textTheme.erpCaption.copyWith(color: t.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '—';
    return _dateFormat.format(value.toLocal());
  }
}
