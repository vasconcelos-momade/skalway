import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../core/theme/table_theme.dart';
import '../../../../../shared/widgets/buttons/pharma_button_loader.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../../shared/widgets/tables/enterprise_table_cells.dart';
import '../../../../pharmacy/products/domain/entities/product.dart';
import 'pdv_catalog_utils.dart';

class PdvProductTable extends StatelessWidget {
  const PdvProductTable({
    super.key,
    required this.items,
    required this.query,
    required this.canAdd,
    required this.addingProductId,
    required this.onAdd,
    this.isLoading = false,
  });

  final List<Product> items;
  final String query;
  final bool canAdd;
  final String? addingProductId;
  final void Function(Product product) onAdd;
  final bool isLoading;

  static const _columns = [
    'PRODUTO',
    'PREÇO',
    'VALIDADE',
    'LOTE',
    'STOCK',
    'AÇÕES',
  ];

  EnterpriseTableStatus get _status {
    if (isLoading && items.isEmpty) return EnterpriseTableStatus.loading;
    if (items.isEmpty) return EnterpriseTableStatus.empty;
    return EnterpriseTableStatus.data;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final tableTheme = context.tableTheme;

    return EnterpriseDataTable(
      adaptive: false,
      showCheckboxColumn: false,
      status: _status,
      isLoading: isLoading,
      emptyTitle: query.isEmpty
          ? 'Nenhum registo encontrado'
          : 'Nenhum produto encontrado.',
      emptyMessage: 'Nenhum registo encontrado',
      emptySubtitle: query.isEmpty ? null : 'Tente outro nome, código ou EAN.',
      dataRowMinHeight: 72,
      dataRowMaxHeight: 92,
      columnSpacing: s.xxl,
      columns: [
        for (final label in _columns)
          enterpriseDataColumn(
            context,
            label,
            numeric: label == 'PREÇO' || label == 'STOCK',
          ),
      ],
      rowCount: items.length,
      rowBuilder: (context, index) {
        final product = items[index];
        final lineId = 'produto:${product.id}';
        final isAdding = addingProductId == lineId;
        final canInteract = canAdd && !isAdding && product.estoqueAtual > 0;

        return DataRow(
          color: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return tableTheme.hoverColor;
            }
            if (index.isOdd) {
              return t.bgSecondary.withValues(alpha: 0.45);
            }
            return null;
          }),
          onSelectChanged: canInteract ? (_) => onAdd(product) : null,
          cells: [
            DataCell(_nameCell(context, product)),
            DataCell(TableNumericCell(pdvFormatMoney(product.precoVenda))),
            DataCell(TableMetadataCell(pdvFormatDate(product.dataValidade))),
            DataCell(TableMetadataCell(product.lote)),
            DataCell(TableNumericCell('${product.estoqueAtual.toInt()}')),
            DataCell(
              Align(
                alignment: Alignment.center,
                child: isAdding
                    ? SizedBox(
                        width: t.minTouchTarget,
                        height: t.minTouchTarget,
                        child: Center(
                          child: PharmaButtonLoader(color: t.brandBlue),
                        ),
                      )
                    : FilledButton.tonalIcon(
                        onPressed: canInteract ? () => onAdd(product) : null,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add'),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _nameCell(BuildContext context, Product product) {
    final substancia = product.nomeGenerico?.trim();
    final title = pdvProductDisplayTitle(
      nomeComercial: product.nomeComercial,
      dosagem: product.dosagem,
      forma: product.forma,
    );

    return TablePrimaryCell(title, subtitle: substancia);
  }
}
