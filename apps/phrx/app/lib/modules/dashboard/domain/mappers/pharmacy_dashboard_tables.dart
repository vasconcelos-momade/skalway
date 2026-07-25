import '../models/dashboard_table_definition.dart';
import '../utils/dashboard_data_utils.dart';

abstract final class PharmacyDashboardTables {
  PharmacyDashboardTables._();

  static const definitions = [
    DashboardTableDefinition(
      title: 'Produtos críticos',
      tableKey: 'produtosCriticos',
      headers: ['Produto', 'Disponível', 'Mínimo'],
      reloadKeySuffix: 'criticos',
      rowBuilder: _produtoCriticoRow,
    ),
    DashboardTableDefinition(
      title: 'Últimas entradas',
      tableKey: 'ultimasEntradas',
      headers: ['Produto', 'Lote', 'Qtd', 'Origem'],
      reloadKeySuffix: 'entradas',
      rowBuilder: _entradaRow,
    ),
    DashboardTableDefinition(
      title: 'Últimas dispensações',
      tableKey: 'ultimasDispensacoes',
      headers: ['Produto', 'Lote', 'Qtd', 'Tipo'],
      reloadKeySuffix: 'dispensacoes',
      rowBuilder: _dispensacaoRow,
    ),
    DashboardTableDefinition(
      title: 'Últimos alertas',
      tableKey: 'ultimosAlertas',
      headers: ['Produto', 'Tipo', 'Mensagem'],
      reloadKeySuffix: 'alertas',
      rowBuilder: _alertaRow,
    ),
  ];

  static List<String> _produtoCriticoRow(Map<String, dynamic> row) => [
        DashboardDataUtils.text(row['nome']),
        DashboardDataUtils.text(row['disponivel']),
        DashboardDataUtils.text(row['minimo']),
      ];

  static List<String> _entradaRow(Map<String, dynamic> row) => [
        DashboardDataUtils.productName(row),
        DashboardDataUtils.text(row['numeroLote']),
        DashboardDataUtils.text(row['quantidade']),
        DashboardDataUtils.text(row['origem']),
      ];

  static List<String> _dispensacaoRow(Map<String, dynamic> row) => [
        DashboardDataUtils.productName(row),
        DashboardDataUtils.text(row['numeroLote']),
        DashboardDataUtils.text(row['quantidade']),
        DashboardDataUtils.text(row['tipoDispensacao']),
      ];

  static List<String> _alertaRow(Map<String, dynamic> row) => [
        DashboardDataUtils.productName(row),
        DashboardDataUtils.text(row['tipo']),
        DashboardDataUtils.text(row['mensagem']),
      ];
}
