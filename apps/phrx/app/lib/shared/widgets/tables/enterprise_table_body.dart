import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/design_metrics.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/extensions.dart';
import '../../../core/theme/pharma_border_tokens.dart';
import '../../../core/theme/table_theme.dart';
import '../../responsive/breakpoints.dart' as responsive;
import '../../responsive/pharma_screen_layout.dart';
import 'enterprise_table_column.dart';
import 'enterprise_table_header.dart';

/// Corpo scrollável da tabela enterprise com header sticky.
///
/// Inclui zebra striping (`surface` / `surfaceContainerLow`), hover, selected
/// e divisores `outlineVariant` — padrão Carbon / Fluent / Material 3.
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
    this.zebraStripes = true,
    this.emptyPlaceholder,
  });

  final EnterpriseTableHeader header;
  final List<DataRow> rows;
  final bool showCheckboxColumn;
  final double? dataRowMinHeight;
  final double? dataRowMaxHeight;
  final double? columnSpacing;
  final String emptyMessage;
  final bool zebraStripes;

  /// Conteúdo do body quando [rows] está vazio (Empty / Loading / Error).
  final Widget? emptyPlaceholder;

  /// Constrói o body a partir de colunas tipadas + items (definição única).
  static EnterpriseTableBody fromColumns<T>({
    Key? key,
    required BuildContext context,
    required List<EnterpriseTableColumn<T>> columns,
    required List<T> items,
    bool showCheckboxColumn = false,
    int? sortColumnIndex,
    bool sortAscending = true,
    ValueChanged<bool?>? onSelectAll,
    double? dataRowMinHeight,
    double? dataRowMaxHeight,
    double? columnSpacing,
    String emptyMessage = 'Nenhum registo encontrado',
    bool zebraStripes = true,
    bool Function(T item, int index)? selected,
    ValueChanged<bool?> Function(T item, int index)? onSelectChanged,
    WidgetStateProperty<Color?>? Function(T item, int index)? color,
  }) {
    final header = EnterpriseTableHeader.fromEnterpriseColumns<T>(
      context,
      columns: columns,
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      onSelectAll: onSelectAll,
    );
    final rows = EnterpriseTableColumn.buildRows<T>(
      context: context,
      items: items,
      columns: columns,
      selected: selected,
      onSelectChanged: onSelectChanged,
      color: color,
    );
    return EnterpriseTableBody(
      key: key,
      header: header,
      rows: rows,
      showCheckboxColumn: showCheckboxColumn,
      dataRowMinHeight: dataRowMinHeight,
      dataRowMaxHeight: dataRowMaxHeight,
      columnSpacing: columnSpacing,
      emptyMessage: emptyMessage,
      zebraStripes: zebraStripes,
    );
  }

  /// Cor base zebra / selected (pintada via [DataRow2.decoration]).
  static Color resolveRowBackground(
    BuildContext context, {
    required int index,
    bool selected = false,
    WidgetStateProperty<Color?>? existing,
    bool? zebraStripes,
  }) {
    final tableTheme = context.tableTheme;
    final useZebra = zebraStripes ?? tableTheme.zebraEnabled;
    if (selected) return tableTheme.selectedColor;
    final custom = existing?.resolve(const <WidgetState>{});
    if (custom != null) return custom;
    if (!useZebra) return tableTheme.zebraEvenColor;
    return index.isOdd ? tableTheme.zebraOddColor : tableTheme.zebraEvenColor;
  }

  /// Overlay InkWell: selected → hover (zebra fica na decoration).
  static WidgetStateProperty<Color?> rowColor(
    BuildContext context, {
    required int index,
    WidgetStateProperty<Color?>? existing,
    bool? zebraStripes,
  }) {
    final tableTheme = context.tableTheme;

    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return tableTheme.selectedColor;
      }
      if (states.contains(WidgetState.hovered)) {
        return tableTheme.hoverColor;
      }
      return resolveRowBackground(
        context,
        index: index,
        existing: existing,
        zebraStripes: zebraStripes,
      );
    });
  }

  DataRow _decorateRow(BuildContext context, DataRow row, int index) {
    final tableTheme = context.tableTheme;
    final borders = context.borders;
    final background = resolveRowBackground(
      context,
      index: index,
      selected: row.selected,
      existing: row.color,
      zebraStripes: zebraStripes,
    );
    final color = rowColor(
      context,
      index: index,
      existing: row.color,
      zebraStripes: zebraStripes,
    );

    // DataTable2: se [DataRow2.decoration] estiver definido, substitui o
    // BoxDecoration interno — é o caminho fiável para zebra visível.
    // Borda de topo: apenas quando zebra está desligada (Carbon / Fluent).
    // Com zebra activa o contraste de cor já separa as linhas; borda seria redundante.
    final decoration = BoxDecoration(
      color: background,
      border: zebraStripes
          ? null
          : Border(
              top: BorderSide(
                color: tableTheme.dividerColor,
                width: borders.borderThin,
              ),
            ),
    );

    if (row is DataRow2) {
      return DataRow2(
        key: row.key,
        selected: row.selected,
        onSelectChanged: row.onSelectChanged,
        onTap: row.onTap,
        onDoubleTap: row.onDoubleTap,
        onLongPress: row.onLongPress,
        onSecondaryTap: row.onSecondaryTap,
        onSecondaryTapDown: row.onSecondaryTapDown,
        color: color,
        decoration: row.decoration ?? decoration,
        specificRowHeight: row.specificRowHeight,
        cells: row.cells,
      );
    }

    return DataRow2(
      key: row.key,
      selected: row.selected,
      onSelectChanged: row.onSelectChanged,
      onLongPress: row.onLongPress,
      color: color,
      decoration: decoration,
      cells: row.cells,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final borders = context.borders;
    final tableTheme = context.tableTheme;
    final isDesktop = PharmaScreenLayout.isDesktop(context);

    final decoratedRows = [
      for (var i = 0; i < rows.length; i++) _decorateRow(context, rows[i], i),
    ];

    // Com zebra activa o contraste já divide as linhas visualmente;
    // dividerThickness próximo de 0 evita a grelha densa (Carbon / Fluent).
    final dividerThickness = zebraStripes ? 0.0 : borders.borderThin;

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: tableTheme.dividerColor,
        dataTableTheme: Theme.of(context).dataTableTheme.copyWith(
              dividerThickness: dividerThickness,
            ),
      ),
      child: DataTable2(
        showCheckboxColumn: showCheckboxColumn,
        sortColumnIndex: header.sortColumnIndex,
        sortAscending: header.sortAscending,
        onSelectAll: header.onSelectAll,
        headingRowColor: WidgetStatePropertyAll(tableTheme.headerBackgroundColor),
        dividerThickness: dividerThickness,
        dataRowHeight: dataRowMaxHeight ?? tableTheme.rowHeight,
        headingRowHeight: DesignMetrics.tableRowHeightMin,
        horizontalMargin: isDesktop ? s.lg : s.md,
        columnSpacing: columnSpacing ?? (isDesktop ? s.xxl : s.lg),
        minWidth: responsive.Breakpoints.tablet,
        fixedTopRows: 1,
        empty: emptyPlaceholder ??
            Center(
              child: Text(
                emptyMessage,
                style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                      color: t.textMuted,
                    ),
              ),
            ),
        columns: header.columns,
        rows: decoratedRows,
      ),
    );
  }
}
