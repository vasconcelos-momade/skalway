import '../models/dashboard_table_definition.dart';
import '../utils/dashboard_data_utils.dart';

abstract final class ExecutiveDashboardTables {
  ExecutiveDashboardTables._();

  static const definitions = [
    DashboardTableDefinition(
      title: 'Últimas vendas',
      tableKey: 'ultimasVendas',
      headers: ['Fatura', 'Cliente', 'Total', 'Estado', 'Data'],
      reloadKeySuffix: 'vendas',
      rowBuilder: _ultimaVendaRow,
    ),
  ];

  static List<String> _ultimaVendaRow(Map<String, dynamic> row) => [
        DashboardDataUtils.text(row['numero']),
        DashboardDataUtils.text(row['clienteNome']),
        DashboardDataUtils.money(row['total']),
        DashboardDataUtils.text(row['estado']),
        DashboardDataUtils.label(row['createdAt']),
      ];
}
