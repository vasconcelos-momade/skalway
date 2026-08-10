import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/extensions.dart';
import '../../../../../core/utils/lote_stock_utils.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../../shared/widgets/tables/enterprise_table_cells.dart';
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
    final s = context.spacing;

    return EnterpriseDataTable(
      adaptive: false,
      showCheckboxColumn: false,
      status: items.isEmpty
          ? EnterpriseTableStatus.empty
          : EnterpriseTableStatus.data,
      emptyTitle: 'Nenhum registo encontrado',
      emptyMessage: 'Nenhum registo encontrado',
      dataRowMinHeight: 64,
      dataRowMaxHeight: 88,
      columnSpacing: s.md,
      columns: [
        for (var i = 0; i < _columnLabels.length; i++)
          enterpriseDataColumn(
            context,
            _columnLabels[i],
            numeric: i >= 3 && i <= 7,
          ),
      ],
      rowCount: items.length,
      rowBuilder: (context, index) {
        final item = items[index];
        return DataRow(
          cells: [
            DataCell(
              TablePrimaryCell(
                item.produtoDisplayLabel,
                subtitle: item.produtoNomeGenerico,
              ),
            ),
            DataCell(TableMetadataCell(item.numeroLote)),
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TableMetadataCell(_formatDate(item.dataValidade)),
                  EstoqueBadges.validade(context, item),
                ],
              ),
            ),
            DataCell(TableNumericCell(item.precoCompra.toStringAsFixed(2))),
            DataCell(
              TableNumericCell(item.precoVenda?.toStringAsFixed(2) ?? '—'),
            ),
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TableNumericCell(
                    LoteStockUtils.formatDisponivelFromNum(item.quantidadeDisponivel),
                  ),
                  EstoqueBadges.stock(context, item),
                ],
              ),
            ),
            DataCell(
              TableNumericCell(
                LoteStockUtils.formatDisponivelFromNum(item.quantidadeQuarentena),
              ),
            ),
            DataCell(
              TableNumericCell(
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

  String _formatDate(DateTime? value) {
    if (value == null) return '—';
    return _dateFormat.format(value.toLocal());
  }
}
