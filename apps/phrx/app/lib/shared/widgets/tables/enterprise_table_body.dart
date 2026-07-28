import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';

import '../../../core/theme/design_metrics.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';
import '../../responsive/breakpoints.dart' as responsive;
import '../../responsive/pharma_screen_layout.dart';
import 'enterprise_table_header.dart';

class EnterpriseTableBody extends StatelessWidget {
  const EnterpriseTableBody({
    super.key,
    required this.header,
    required this.rows,
    this.showCheckboxColumn = true,
    this.dataRowMinHeight,
    this.dataRowMaxHeight,
    this.columnSpacing,
    this.emptyMessage = 'Nenhum registo encontrado',
  });

  final EnterpriseTableHeader header;
  final List<DataRow> rows;
  final bool showCheckboxColumn;
  final double? dataRowMinHeight;
  final double? dataRowMaxHeight;
  final double? columnSpacing;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return DataTable2(
      showCheckboxColumn: showCheckboxColumn,
      sortColumnIndex: header.sortColumnIndex,
      sortAscending: header.sortAscending,
      onSelectAll: header.onSelectAll,
      headingRowColor: WidgetStatePropertyAll(
        t.bgSecondary.withValues(alpha: 0.92),
      ),
      dataRowHeight: dataRowMaxHeight ?? DesignMetrics.tableRowHeightMax,
      headingRowHeight: DesignMetrics.tableRowHeightMin,
      horizontalMargin: PharmaScreenLayout.isDesktop(context) ? s.lg : s.md,
      columnSpacing: columnSpacing ??
          (PharmaScreenLayout.isDesktop(context) ? s.xxl : s.lg),
      minWidth: responsive.Breakpoints.tablet,
      fixedTopRows: 1,
      empty: Center(
        child: Text(
          emptyMessage,
          style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                color: t.textMuted,
              ),
        ),
      ),
      columns: header.columns,
      rows: rows,
    );
  }
}
