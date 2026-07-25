import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';

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
    final t = context.pharmaTokens;
    final s = context.spacing;
    final textTheme = Theme.of(context).textTheme;

    return EnterpriseDataTable(
      adaptive: false,
      showCheckboxColumn: false,
      dataRowMinHeight: 56,
      dataRowMaxHeight: 72,
      columnSpacing: s.md,
      columns: [
        for (var i = 0; i < _columnLabels.length; i++)
          DataColumn(
            numeric: i >= 2 && i <= 4,
            label: Text(
              _columnLabels[i].toUpperCase(),
              style: textTheme.erpTableHeader.copyWith(color: t.textMuted),
            ),
          ),
      ],
      rowCount: items.length,
      rowBuilder: (context, index) {
        final row = items[index];
        return DataRow(
          cells: [
            DataCell(Text(formatDateTime(row['data']?.toString() ?? ''))),
            DataCell(Text(row['tipo']?.toString() ?? '—')),
            DataCell(Text(formatMoney(row['valor']))),
            DataCell(Text(formatMoney(row['saldoAnterior']))),
            DataCell(Text(formatMoney(row['saldoFinal']))),
            DataCell(Text(row['descricao']?.toString() ?? '—')),
          ],
        );
      },
    );
  }
}
