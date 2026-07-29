import 'package:flutter/material.dart';

import 'enterprise_table_column.dart';

/// Configuração semântica do cabeçalho sticky da tabela enterprise.
///
/// Utilizamos [DataTable2] (`fixedTopRows: 1`) para sticky header + alinhamento
/// perfeito com o body. Esta classe encapsula as colunas partilhadas —
/// preferir [EnterpriseTableColumn] para width/alignment únicos.
class EnterpriseTableHeader {
  const EnterpriseTableHeader({
    required this.columns,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSelectAll,
  });

  /// Colunas Flutter ([DataColumn] / [DataColumn2]) já resolvidas.
  final List<DataColumn> columns;
  final int? sortColumnIndex;
  final bool sortAscending;
  final ValueChanged<bool?>? onSelectAll;

  /// Constrói o header a partir de [EnterpriseTableColumn] tipadas —
  /// garante a mesma definição de colunas no Body.
  static EnterpriseTableHeader fromEnterpriseColumns<T>(
    BuildContext context, {
    required List<EnterpriseTableColumn<T>> columns,
    int? sortColumnIndex,
    bool sortAscending = true,
    ValueChanged<bool?>? onSelectAll,
  }) {
    return EnterpriseTableHeader(
      columns: EnterpriseTableColumn.toDataColumns(context, columns),
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      onSelectAll: onSelectAll,
    );
  }
}
