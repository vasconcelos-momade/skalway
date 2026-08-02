import 'package:flutter/material.dart';

import '../../../../core/theme/extensions.dart';
import '../../../../shared/widgets/dashboard/enterprise_filter_bar.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/tables/enterprise_table_cells.dart';
import '../../../dashboard/domain/dashboard_query.dart';

class CashflowTable extends StatelessWidget {
  const CashflowTable({
    super.key,
    required this.items,
    required this.formatDateTime,
    required this.formatMoney,
    this.searchController,
    this.searchHint = 'Pesquisar descrição...',
    this.onSearchChanged,
    this.isLoading = false,
    this.query = const DashboardQuery(),
    this.onQueryChanged,
    this.toolbarActions,
    this.pagination,
    this.errorMessage,
    this.onRetry,
  });

  final List<Map<String, dynamic>> items;
  final String Function(String) formatDateTime;
  final String Function(dynamic) formatMoney;
  final TextEditingController? searchController;
  final String searchHint;
  final ValueChanged<String>? onSearchChanged;
  final bool isLoading;
  final DashboardQuery query;
  final ValueChanged<DashboardQuery>? onQueryChanged;
  final List<Widget>? toolbarActions;
  final Widget? pagination;
  final String? errorMessage;
  final VoidCallback? onRetry;

  static const _columnLabels = [
    'Data',
    'Tipo',
    'Valor (MZN)',
    'Saldo anterior',
    'Saldo final',
    'Descrição',
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    return EnterpriseDataTable(
      adaptive: false,
      showCheckboxColumn: false,
      dataRowMinHeight: 56,
      dataRowMaxHeight: 72,
      columnSpacing: s.md,
      searchController: searchController,
      searchHint: searchHint,
      onSearchChanged: onSearchChanged,
      isLoading: isLoading,
      hasActiveFilters: query.hasActiveFilters,
      onClearFilters: onQueryChanged == null
          ? null
          : () => onQueryChanged!(const DashboardQuery()),
      onApplyFilters: () {},
      filterWidgets: onQueryChanged == null
          ? null
          : [
              EnterpriseFilterBar(
                query: query,
                onChanged: onQueryChanged!,
              ),
            ],
      toolbarActions: toolbarActions,
      pagination: pagination,
      emptyMessage: 'Sem resultados para os filtros selecionados.',
      errorMessage: errorMessage,
      onRetry: onRetry,
      columns: [
        for (var i = 0; i < _columnLabels.length; i++)
          enterpriseDataColumn(
            context,
            _columnLabels[i],
            numeric: i >= 2 && i <= 4,
          ),
      ],
      rowCount: items.length,
      rowBuilder: (context, index) {
        final row = items[index];
        return DataRow(
          cells: [
            DataCell(
              TableMetadataCell(formatDateTime(row['data']?.toString() ?? '')),
            ),
            DataCell(TableSecondaryCell(row['tipo']?.toString() ?? '—')),
            DataCell(TableNumericCell(formatMoney(row['valor']))),
            DataCell(TableNumericCell(formatMoney(row['saldoAnterior']))),
            DataCell(TableNumericCell(formatMoney(row['saldoFinal']))),
            DataCell(TableSecondaryCell(row['descricao']?.toString() ?? '—')),
          ],
        );
      },
    );
  }
}
