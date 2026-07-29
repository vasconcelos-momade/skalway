import 'package:flutter/material.dart';

import '../../../../core/theme/extensions.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/tables/enterprise_table_cells.dart';

class CashflowTable extends StatelessWidget {
  const CashflowTable({
    super.key,
    required this.items,
    required this.formatDateTime,
    required this.formatMoney,
  });

  final List<Map<String, dynamic>> items;
  final String Function(String) formatDateTime;
  final String Function(dynamic) formatMoney;

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
