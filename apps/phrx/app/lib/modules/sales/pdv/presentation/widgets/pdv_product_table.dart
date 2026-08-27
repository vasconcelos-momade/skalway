import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../core/theme/table_theme.dart';
import '../../../../../shared/widgets/buttons/pharma_button_loader.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../../shared/widgets/tables/enterprise_table_cells.dart';
import '../../../../pharmacy/products/domain/entities/product.dart';
import 'pdv_catalog_utils.dart';
import 'pdv_qty_field.dart';

class PdvProductTable extends StatefulWidget {
  const PdvProductTable({
    super.key,
    required this.items,
    required this.query,
    required this.canAdd,
    required this.addingProductId,
    required this.onAdd,
    this.isLoading = false,
    this.pagination,
  });

  final List<Product> items;
  final String query;
  final bool canAdd;
  final String? addingProductId;
  final void Function(Product product, int quantidade) onAdd;
  final bool isLoading;
  final Widget? pagination;

  @override
  State<PdvProductTable> createState() => _PdvProductTableState();
}

class _PdvProductTableState extends State<PdvProductTable> {
  static const _columns = [
    'PRODUTO',
    'PREÇO',
    'VALIDADE',
    'LOTE',
    'STOCK',
    'QTD',
    'AÇÕES',
  ];

  /// Quantidade por produto (default 1).
  final Map<String, int> _qtyByProductId = {};

  EnterpriseTableStatus get _status {
    if (widget.isLoading && widget.items.isEmpty) {
      return EnterpriseTableStatus.loading;
    }
    if (widget.items.isEmpty) return EnterpriseTableStatus.empty;
    return EnterpriseTableStatus.data;
  }

  int _qtyFor(Product product) {
    final stock = product.estoqueAtual.toInt();
    final current = _qtyByProductId[product.id] ?? 1;
    if (stock < 1) return 1;
    if (current > stock) return stock;
    if (current < 1) return 1;
    return current;
  }

  void _setQty(Product product, int qty) {
    setState(() => _qtyByProductId[product.id] = qty);
  }

  void _handleAdd(Product product) {
    widget.onAdd(product, _qtyFor(product));
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
      isLoading: widget.isLoading,
      emptyTitle: widget.query.isEmpty
          ? 'Nenhum registo encontrado'
          : 'Nenhum produto encontrado.',
      emptyMessage: 'Nenhum registo encontrado',
      emptySubtitle:
          widget.query.isEmpty ? null : 'Tente outro nome, código ou EAN.',
      dataRowMinHeight: 72,
      dataRowMaxHeight: 92,
      columnSpacing: s.xxl,
      pagination: widget.pagination,
      columns: [
        for (final label in _columns)
          enterpriseDataColumn(
            context,
            label,
            numeric: label == 'PREÇO' || label == 'STOCK' || label == 'QTD',
          ),
      ],
      rowCount: widget.items.length,
      rowBuilder: (context, index) {
        final product = widget.items[index];
        final lineId = 'produto:${product.id}';
        final isAdding = widget.addingProductId == lineId;
        final canInteract =
            widget.canAdd && !isAdding && product.estoqueAtual > 0;
        final stock = product.estoqueAtual.toInt();

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
          onSelectChanged: canInteract ? (_) => _handleAdd(product) : null,
          cells: [
            DataCell(_nameCell(context, product)),
            DataCell(TableNumericCell(pdvFormatMoney(product.precoVenda))),
            DataCell(TableMetadataCell(pdvFormatDate(product.dataValidade))),
            DataCell(TableMetadataCell(product.lote)),
            DataCell(TableNumericCell('$stock')),
            DataCell(
              Align(
                alignment: Alignment.center,
                child: PdvQtyField(
                  key: ValueKey('qty-${product.id}'),
                  maxStock: stock,
                  value: _qtyFor(product),
                  enabled: canInteract,
                  onChanged: (qty) => _setQty(product, qty),
                ),
              ),
              onTap: () {},
            ),
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
                        onPressed:
                            canInteract ? () => _handleAdd(product) : null,
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
