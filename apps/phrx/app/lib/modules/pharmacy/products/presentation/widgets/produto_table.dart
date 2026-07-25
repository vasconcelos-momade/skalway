import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../core/theme/table_theme.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../domain/entities/product.dart';
import 'produto_categoria_chip.dart';

/// Tabela desktop/web do catálogo master — layout SaaS com hierarquia visual na coluna Nome.
class ProdutoTable extends StatelessWidget {
  const ProdutoTable({
    super.key,
    required this.items,
    required this.sortBy,
    required this.sortOrder,
    required this.onSort,
    required this.onAction,
  });

  final List<Product> items;
  final String sortBy;
  final String sortOrder;
  final void Function(String column, String order) onSort;
  final void Function(Product, String) onAction;

  static const _columnLabels = [
    'Nome',
    'Categoria',
    'Estoque',
    'Status',
    'Ações',
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final tableTheme = context.tableTheme;

    return EnterpriseDataTable(
      adaptive: false,
      showCheckboxColumn: false,
      sortColumnIndex: _sortColumnIndex(),
      sortAscending: sortOrder == 'asc',
      dataRowMinHeight: 72,
      dataRowMaxHeight: 92,
      columnSpacing: s.xxl,
      columns: [
        for (var i = 0; i < _columnLabels.length; i++)
          _buildColumn(
            context,
            label: _columnLabels[i],
            onSort: _sortKeyForIndex(i) != null
                ? () => _handleSort(_sortKeyForIndex(i)!)
                : null,
            numeric: i == 2,
          ),
      ],
      rowCount: items.length,
      rowBuilder: (context, index) {
        final product = items[index];
        final isCriticalStock =
            product.estoqueMinimo > 0 && product.estoqueAtual <= product.estoqueMinimo;

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
          cells: [
            DataCell(
              _nameCell(context, product),
            ),
            DataCell(
              ProdutoCategoriaChip(
                label: product.categoriaNome ?? '—',
                categoriaCodigo: product.categoriaCodigoFnm,
              ),
            ),
            DataCell(
              _stockCell(context, product, isCriticalStock),
            ),
            DataCell(
              _statusCell(context, product.ativo),
            ),
            DataCell(
              Align(
                alignment: Alignment.center,
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: t.textMuted, size: t.iconMd),
                  tooltip: 'Acções',
                  onSelected: (action) => onAction(product, action),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'editar', child: Text('Editar')),
                    PopupMenuItem(value: 'excluir', child: Text('Eliminar')),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  DataColumn _buildColumn(
    BuildContext context, {
    required String label,
    VoidCallback? onSort,
    bool numeric = false,
  }) {
    final t = context.pharmaTokens;
    final textTheme = Theme.of(context).textTheme;

    return DataColumn(
      numeric: numeric,
      label: Text(
        label.toUpperCase(),
        style: textTheme.erpTableHeader.copyWith(color: t.textMuted),
      ),
      onSort: onSort == null ? null : (_, _) => onSort(),
    );
  }

  Widget _nameCell(BuildContext context, Product product) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    final substancia = product.nomeGenerico?.trim();
    final formaDosagem = [
      product.forma?.trim(),
      product.dosagem?.trim(),
    ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: s.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            product.nomeComercial,
            style: textTheme.erpTablePrimary.copyWith(color: t.textPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (substancia != null && substancia.isNotEmpty) ...[
            SizedBox(height: s.xxs),
            Text(
              substancia,
              style: textTheme.erpTableSecondary.copyWith(color: t.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (formaDosagem.isNotEmpty) ...[
            SizedBox(height: s.xxs),
            Text(
              formaDosagem,
              style: textTheme.erpTableMeta.copyWith(color: t.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _stockCell(BuildContext context, Product product, bool isCriticalStock) {
    final t = context.pharmaTokens;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatNumber(product.estoqueAtual),
          style: textTheme.erpTablePrimary.copyWith(
            color: isCriticalStock ? t.posDanger : t.textPrimary,
          ),
        ),
        if (product.estoqueMinimo > 0)
          Text(
            'Mín. ${_formatNumber(product.estoqueMinimo)}',
            style: textTheme.erpTableMeta.copyWith(color: t.textMuted),
          ),
      ],
    );
  }

  Widget _statusCell(BuildContext context, bool active) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    final color = active ? t.brandGreen : t.textMuted;
    final label = active ? 'Activo' : 'Inactivo';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: s.xs),
        Text(
          label,
          style: textTheme.erpTableSecondary.copyWith(color: t.textSecondary),
        ),
      ],
    );
  }

  String? _sortKeyForIndex(int index) {
    return switch (index) {
      0 => 'nome',
      2 => 'estoqueAtual',
      _ => null,
    };
  }

  int? _sortColumnIndex() {
    return switch (sortBy) {
      'nome' => 0,
      'estoqueAtual' => 2,
      _ => null,
    };
  }

  void _handleSort(String column) {
    if (sortBy == column) {
      onSort(column, sortOrder == 'asc' ? 'desc' : 'asc');
    } else {
      onSort(column, 'asc');
    }
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}
