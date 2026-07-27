import '../models/dashboard_table_definition.dart';
import '../utils/dashboard_data_utils.dart';

abstract final class PharmacyDashboardTables {
  PharmacyDashboardTables._();

  static const definitions = [
    DashboardTableDefinition(
      title: 'Produtos críticos',
      tableKey: 'produtosCriticos',
      headers: ['Produto', 'Stock', 'Mínimo', 'Validade'],
      reloadKeySuffix: 'criticos',
      rowBuilder: _produtoCriticoRow,
    ),
    DashboardTableDefinition(
      title: 'Últimas dispensações',
      tableKey: 'ultimasDispensacoes',
      headers: ['Produto', 'Lote', 'Qtd', 'Tipo', 'Data'],
      reloadKeySuffix: 'dispensacoes',
      rowBuilder: _dispensacaoRow,
    ),
    DashboardTableDefinition(
      title: 'Últimos alertas',
      tableKey: 'ultimosAlertas',
      headers: ['Produto', 'Tipo', 'Mensagem', 'Data'],
      reloadKeySuffix: 'alertas',
      rowBuilder: _alertaRow,
    ),
  ];

  static List<String> _produtoCriticoRow(Map<String, dynamic> row) => [
        DashboardDataUtils.text(row['nome']),
        DashboardDataUtils.text(row['disponivel']),
        DashboardDataUtils.text(row['minimo']),
        DashboardDataUtils.label(row['validade']),
      ];

  static List<String> _dispensacaoRow(Map<String, dynamic> row) => [
        DashboardDataUtils.productName(row),
        DashboardDataUtils.text(row['numeroLote']),
        DashboardDataUtils.text(row['quantidade']),
        DashboardDataUtils.text(row['tipoDispensacao']),
        DashboardDataUtils.label(row['createdAt']),
      ];

  static List<String> _alertaRow(Map<String, dynamic> row) => [
        DashboardDataUtils.productName(row),
        DashboardDataUtils.text(row['tipo']),
        DashboardDataUtils.text(row['mensagem']),
        DashboardDataUtils.label(row['createdAt']),
      ];
}
