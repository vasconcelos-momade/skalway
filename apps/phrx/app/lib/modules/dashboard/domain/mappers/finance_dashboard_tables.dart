import '../models/dashboard_table_definition.dart';
import '../utils/dashboard_data_utils.dart';

abstract final class FinanceDashboardTables {
  FinanceDashboardTables._();

  static const definitions = [
    DashboardTableDefinition(
      title: 'Últimas movimentações financeiras',
      tableKey: 'fluxoCaixa',
      headers: ['Data', 'Tipo', 'Descrição', 'Valor', 'Estado'],
      reloadKeySuffix: 'fluxo',
      rowBuilder: _movimentoRow,
    ),
  ];

  static List<String> _movimentoRow(Map<String, dynamic> row) => [
        DashboardDataUtils.label(row['createdAt']),
        DashboardDataUtils.text(row['tipo']),
        DashboardDataUtils.text(row['referencia']),
        DashboardDataUtils.money(row['valor']),
        DashboardDataUtils.text(row['status'] ?? '—'),
      ];
}
