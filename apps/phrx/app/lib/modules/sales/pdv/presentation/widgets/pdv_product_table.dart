import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../core/theme/table_theme.dart';
import '../../../../../shared/widgets/buttons/pharma_button_loader.dart';
import '../../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../../shared/widgets/tables/table_typography.dart';
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
  });

  final List<Product> items;
  final String query;
  final bool canAdd;
  final String? addingProductId;
  final void Function(Product product) onAdd;

  static const _columns = [
    'PRODUTO',
    'PREÇO',
    'VALIDADE',
    'LOTE',
    'STOCK',
    'AÇÕES',
  ];

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ModuleEmptyState(
        title: query.isEmpty
            ? 'Nenhum produto disponível.'
            : 'Nenhum produto encontrado.',
        subtitle: query.isEmpty ? null : 'Tente outro nome, código ou EAN.',
      );
    }

    final t = context.pharmaTokens;
    final s = context.spacing;
    final tableTheme = context.tableTheme;

    return EnterpriseDataTable(
      adaptive: false,
      showCheckboxColumn: false,
      dataRowMinHeight: 72,
      dataRowMaxHeight: 92,
      columnSpacing: s.xxl,
      columns: [
        for (final label in _columns)
          DataColumn(label: TableTypography.headerLabel(context, label)),
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
            DataCell(TableTypography.cellText(context, pdvFormatMoney(product.precoVenda))),
            DataCell(TableTypography.cellText(context, pdvFormatDate(product.dataValidade))),
            DataCell(
              TableTypography.cellText(
                context,
                product.lote?.trim().isNotEmpty == true ? product.lote! : '—',
              ),
            ),
            DataCell(
              TableTypography.cellText(
                context,
                '${product.estoqueAtual.toInt()}',
                style: TableTypography.primary(context),
              ),
            ),
            DataCell(
              Align(
                alignment: Alignment.center,
                child: isAdding
                    ? SizedBox(
                        width: t.minTouchTarget,
                        height: t.minTouchTarget,
                        child: Center(child: PharmaButtonLoader(color: t.brandBlue)),
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
    final t = context.pharmaTokens;
    final s = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    final substancia = product.nomeGenerico?.trim();
    final title = pdvProductDisplayTitle(
      nomeComercial: product.nomeComercial,
      dosagem: product.dosagem,
      forma: product.forma,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: textTheme.erpTablePrimary.copyWith(color: t.textPrimary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (substancia != null && substancia.isNotEmpty) ...[
          SizedBox(height: s.xxs),
          Text(
            substancia,
            style: textTheme.erpTableMeta.copyWith(color: t.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
