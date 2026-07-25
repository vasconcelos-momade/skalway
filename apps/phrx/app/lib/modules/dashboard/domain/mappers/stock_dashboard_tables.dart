import '../models/dashboard_table_definition.dart';
import '../utils/dashboard_data_utils.dart';

abstract final class StockDashboardTables {
  StockDashboardTables._();

  static const definitions = [
    DashboardTableDefinition(
      title: 'Últimos movimentos',
      tableKey: 'ultimosMovimentos',
      headers: ['Tipo', 'Produto', 'Qtd', 'Origem'],
      reloadKeySuffix: 'mov',
      rowBuilder: _movimentoRow,
    ),
    DashboardTableDefinition(
      title: 'Produtos críticos',
      tableKey: 'produtosCriticos',
      headers: ['Produto', 'Disponível', 'Mínimo'],
      reloadKeySuffix: 'criticos',
      rowBuilder: _produtoCriticoRow,
    ),
    DashboardTableDefinition(
      title: 'Inventários',
      tableKey: 'inventarios',
      headers: ['Código', 'Estado', 'Início'],
      reloadKeySuffix: 'inv',
      rowBuilder: _inventarioRow,
    ),
    DashboardTableDefinition(
      title: 'Entradas de compra',
      tableKey: 'entradasCompra',
      headers: ['Produto', 'Lote', 'Fornecedor', 'Valor'],
      reloadKeySuffix: 'entradas-compra',
      rowBuilder: _entradaCompraRow,
    ),
    DashboardTableDefinition(
      title: 'Reservas',
      tableKey: 'reservas',
      headers: ['Produto', 'Lote', 'Qtd', 'Expira'],
      reloadKeySuffix: 'res',
      rowBuilder: _reservaRow,
    ),
    DashboardTableDefinition(
      title: 'Incinerações',
      tableKey: 'incineracoes',
      headers: ['Auto', 'Data'],
      reloadKeySuffix: 'inc',
      rowBuilder: _incineracaoRow,
    ),
  ];

  static List<String> _movimentoRow(Map<String, dynamic> row) => [
        DashboardDataUtils.text(row['tipo']),
        DashboardDataUtils.productName(row),
        DashboardDataUtils.text(row['quantidade']),
        DashboardDataUtils.text(row['origem']),
      ];

  static List<String> _produtoCriticoRow(Map<String, dynamic> row) => [
        DashboardDataUtils.productName(row),
        DashboardDataUtils.text(row['disponivel']),
        DashboardDataUtils.text(row['minimo']),
      ];

  static List<String> _inventarioRow(Map<String, dynamic> row) => [
        DashboardDataUtils.text(row['codigo']),
        DashboardDataUtils.text(row['status']),
        DashboardDataUtils.label(row['iniciadoEm']),
      ];

  static List<String> _entradaCompraRow(Map<String, dynamic> row) => [
        DashboardDataUtils.text(row['produtoNomeComercial']),
        DashboardDataUtils.text(row['numeroLote']),
        DashboardDataUtils.text(row['fornecedorNome']),
        DashboardDataUtils.text(row['valorCompra']),
      ];

  static List<String> _reservaRow(Map<String, dynamic> row) => [
        DashboardDataUtils.productName(row),
        DashboardDataUtils.text(row['numeroLote']),
        DashboardDataUtils.text(row['quantidade']),
        DashboardDataUtils.label(row['expiresAt']),
      ];

  static List<String> _incineracaoRow(Map<String, dynamic> row) => [
        DashboardDataUtils.text(row['numeroAuto']),
        DashboardDataUtils.label(row['dataIncineracao']),
      ];
}
