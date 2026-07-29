import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import 'enterprise_table_cells.dart';

/// Alinhamento partilhado entre header e células do corpo.
enum EnterpriseColumnAlignment {
  start,
  center,
  end,
}

/// Definição única de coluna partilhada entre Header e Body.
///
/// Garante o mesmo [width], [alignment] e label em toda a tabela —
/// evita desalinhamento header × body.
class EnterpriseTableColumn<T> {
  const EnterpriseTableColumn({
    required this.label,
    this.id,
    this.width,
    this.minWidth,
    this.size = ColumnSize.M,
    this.alignment = EnterpriseColumnAlignment.start,
    this.sortable = false,
    this.filterable = false,
    this.numeric = false,
    this.tooltip,
    this.renderCell,
    this.onSort,
  });

  /// Identificador opcional (ex.: chave de ordenação / filtro).
  final String? id;

  /// Texto do cabeçalho.
  final String label;

  /// Largura fixa em px (mapeada para [DataColumn2.fixedWidth]).
  final double? width;

  /// Largura mínima em px.
  final double? minWidth;

  /// Tamanho relativo quando [width] é nulo.
  final ColumnSize size;

  final EnterpriseColumnAlignment alignment;
  final bool sortable;
  final bool filterable;

  /// Alinha conteúdo à direita (padrão Material para colunas numéricas).
  final bool numeric;

  final String? tooltip;

  /// Constrói a célula do corpo para o item [item].
  final Widget Function(BuildContext context, T item, int index)? renderCell;

  /// Callback de ordenação (coluna já é esta).
  final void Function(int columnIndex, bool ascending)? onSort;

  MainAxisAlignment get mainAxisAlignment => switch (alignment) {
        EnterpriseColumnAlignment.start => MainAxisAlignment.start,
        EnterpriseColumnAlignment.center => MainAxisAlignment.center,
        EnterpriseColumnAlignment.end => MainAxisAlignment.end,
      };

  Alignment get cellAlignment => switch (alignment) {
        EnterpriseColumnAlignment.start => Alignment.centerLeft,
        EnterpriseColumnAlignment.center => Alignment.center,
        EnterpriseColumnAlignment.end => Alignment.centerRight,
      };

  TextAlign get textAlign => switch (alignment) {
        EnterpriseColumnAlignment.start => TextAlign.start,
        EnterpriseColumnAlignment.center => TextAlign.center,
        EnterpriseColumnAlignment.end => TextAlign.end,
      };

  /// Converte para [DataColumn2] — mesma largura/alinhamento no header sticky.
  DataColumn2 toDataColumn(BuildContext context, {int columnIndex = 0}) {
    final effectiveNumeric =
        numeric || alignment == EnterpriseColumnAlignment.end;

    return DataColumn2(
      label: TableHeaderCell(label),
      tooltip: tooltip,
      numeric: effectiveNumeric,
      size: size,
      fixedWidth: width,
      minWidth: minWidth,
      headingRowAlignment: switch (alignment) {
        EnterpriseColumnAlignment.start => MainAxisAlignment.start,
        EnterpriseColumnAlignment.center => MainAxisAlignment.center,
        EnterpriseColumnAlignment.end => MainAxisAlignment.end,
      },
      onSort: sortable && onSort != null
          ? (i, ascending) => onSort!(columnIndex, ascending)
          : null,
    );
  }

  /// Envolve a célula com o alinhamento da coluna.
  Widget alignCell(Widget child) {
    if (alignment == EnterpriseColumnAlignment.start && !numeric) {
      return child;
    }
    return Align(alignment: cellAlignment, child: child);
  }

  /// Converte lista de colunas tipadas em [DataColumn]s partilhados.
  static List<DataColumn> toDataColumns<T>(
    BuildContext context,
    List<EnterpriseTableColumn<T>> columns,
  ) {
    return [
      for (var i = 0; i < columns.length; i++)
        columns[i].toDataColumn(context, columnIndex: i),
    ];
  }

  /// Constrói linhas a partir de [items] e das colunas tipadas.
  static List<DataRow> buildRows<T>({
    required BuildContext context,
    required List<T> items,
    required List<EnterpriseTableColumn<T>> columns,
    bool Function(T item, int index)? selected,
    ValueChanged<bool?> Function(T item, int index)? onSelectChanged,
    WidgetStateProperty<Color?>? Function(T item, int index)? color,
  }) {
    return [
      for (var i = 0; i < items.length; i++)
        DataRow(
          selected: selected?.call(items[i], i) ?? false,
          onSelectChanged: onSelectChanged != null
              ? onSelectChanged(items[i], i)
              : null,
          color: color?.call(items[i], i),
          cells: [
            for (final col in columns)
              DataCell(
                col.alignCell(
                  col.renderCell?.call(context, items[i], i) ??
                      const SizedBox.shrink(),
                ),
              ),
          ],
        ),
    ];
  }
}
