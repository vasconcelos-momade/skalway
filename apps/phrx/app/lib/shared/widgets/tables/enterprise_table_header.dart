import 'package:flutter/material.dart';

/// Configuração semântica do cabeçalho da tabela enterprise.
/// 
/// Como utilizamos o `DataTable2` para garantir o alinhamento perfeito e
/// responsivo entre cabeçalho e corpo, o cabeçalho não pode ser um widget 
/// fisicamente separado. Esta classe encapsula as propriedades do cabeçalho
/// para manter a organização e reutilização dos componentes.
class EnterpriseTableHeader {
  const EnterpriseTableHeader({
    required this.columns,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSelectAll,
  });

  final List<DataColumn> columns;
  final int? sortColumnIndex;
  final bool sortAscending;
  final ValueChanged<bool?>? onSelectAll;
}
