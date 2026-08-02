import '../models/dashboard_table_definition.dart';
import '../utils/dashboard_data_utils.dart';

abstract final class CashierDashboardTables {
  CashierDashboardTables._();

  static const definitions = [
    DashboardTableDefinition(
      title: 'Últimas vendas',
      tableKey: 'ultimasVendas',
      headers: ['Fatura', 'Cliente', 'Total', 'Pagamento', 'Data'],
      reloadKeySuffix: 'vendas',
      rowBuilder: _ultimaVendaRow,
    ),
    DashboardTableDefinition(
      title: 'Movimento do caixa',
      tableKey: 'movimentosCaixa',
      headers: ['Tipo', 'Terminal', 'Valor', 'Saldo', 'Data'],
      reloadKeySuffix: 'movimentos',
      rowBuilder: _movimentoRow,
    ),
  ];

  static List<String> _ultimaVendaRow(Map<String, dynamic> row) => [
        DashboardDataUtils.text(row['numero']),
        DashboardDataUtils.text(row['clienteNome']),
        DashboardDataUtils.money(row['total']),
        DashboardDataUtils.text(row['tipoPagamento']),
        DashboardDataUtils.label(row['createdAt']),
      ];

  static List<String> _movimentoRow(Map<String, dynamic> row) => [
        DashboardDataUtils.text(row['tipo']),
        DashboardDataUtils.text(row['terminal']),
        DashboardDataUtils.money(row['valor']),
        DashboardDataUtils.money(row['saldoFinal']),
        DashboardDataUtils.label(row['createdAt']),
      ];
}
