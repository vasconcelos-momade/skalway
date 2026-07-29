import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/widgets/menus/enterprise_actions_menu_button.dart';
import '../../../../../shared/widgets/menus/enterprise_dropdown_menu.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../../shared/widgets/tables/enterprise_table_cells.dart';
import '../../domain/entities/product.dart';

/// Tabela desktop/web do catálogo master.
class ProdutoTable extends StatelessWidget {
  const ProdutoTable({
    super.key,
    required this.items,
    required this.sortBy,
    required this.sortOrder,
    required this.onSort,
    required this.onAction,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.onCreate,
    this.hasActiveFilters = false,
    this.onClearFilters,
    this.pagination,
  });

  final List<Product> items;
  final String sortBy;
  final String sortOrder;
  final void Function(String column, String order) onSort;
  final void Function(Product, String) onAction;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onCreate;
  final bool hasActiveFilters;
  final VoidCallback? onClearFilters;
  final Widget? pagination;

  static const _columnLabels = [
    'Produto',
    'Dosagem',
    'Forma',
    'Stock min',
    'Status',
    'Ações',
  ];

  EnterpriseTableStatus get _status {
    if (isLoading && items.isEmpty) return EnterpriseTableStatus.loading;
    if (errorMessage != null && items.isEmpty) return EnterpriseTableStatus.error;
    if (items.isEmpty) return EnterpriseTableStatus.empty;
    return EnterpriseTableStatus.data;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    return EnterpriseDataTable(
      adaptive: false,
      showCheckboxColumn: false,
      status: _status,
      isLoading: isLoading,
      errorMessage: errorMessage,
      errorTitle: 'Falha ao carregar produtos',
      onRetry: onRetry,
      emptyTitle: 'Nenhum produto encontrado',
      emptySubtitle: 'Ajuste os filtros ou crie um novo produto.',
      emptyPrimaryActionLabel: onCreate != null ? 'Novo produto' : null,
      onEmptyPrimaryAction: onCreate,
      hasActiveFilters: hasActiveFilters,
      onClearFilters: onClearFilters,
      sortColumnIndex: _sortColumnIndex(),
      sortAscending: sortOrder == 'asc',
      dataRowMinHeight: 56,
      dataRowMaxHeight: 72,
      columnSpacing: s.xxl,
      zebraStripes: true,
      pagination: pagination,
      columns: [
        for (var i = 0; i < _columnLabels.length; i++)
          enterpriseDataColumn(
            context,
            _columnLabels[i],
            numeric: i == 3,
            onSort: _sortKeyForIndex(i) != null
                ? (_, _) => _handleSort(_sortKeyForIndex(i)!)
                : null,
          ),
      ],
      rowCount: items.length,
      rowBuilder: (context, index) {
        final product = items[index];
        final isCriticalStock = product.estoqueMinimo > 0 &&
            product.estoqueAtual <= product.estoqueMinimo;

        return DataRow(
          cells: [
            DataCell(
              TablePrimaryCell(
                product.nomeComercial,
                subtitle: product.nomeGenerico?.trim(),
              ),
            ),
            DataCell(TableMetadataCell(product.dosagem)),
            DataCell(TableMetadataCell(product.forma)),
            DataCell(
              TableNumericCell(
                _formatNumber(product.estoqueMinimo),
                color: isCriticalStock
                    ? context.pharmaTokens.posDanger
                    : null,
              ),
            ),
            DataCell(
              TableStatusCell(
                label: product.ativo ? 'Activo' : 'Inactivo',
                active: product.ativo,
              ),
            ),
            DataCell(
              Align(
                alignment: Alignment.center,
                child: EnterpriseActionsMenuButton<String>(
                  compact: true,
                  items: const [
                    EnterpriseDropdownItem(
                      value: 'editar',
                      label: 'Editar',
                      icon: Icons.edit_outlined,
                    ),
                    EnterpriseDropdownItem(
                      value: 'excluir',
                      label: 'Eliminar',
                      icon: Icons.delete_outline,
                      destructive: true,
                    ),
                  ],
                  onSelected: (action) => onAction(product, action),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String? _sortKeyForIndex(int index) {
    return switch (index) {
      0 => 'nome',
      3 => 'estoqueMinimo',
      _ => null,
    };
  }

  int? _sortColumnIndex() {
    return switch (sortBy) {
      'nome' => 0,
      'estoqueMinimo' || 'estoqueAtual' => 3,
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
