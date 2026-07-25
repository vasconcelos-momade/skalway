typedef DashboardTableRowBuilder = List<String> Function(Map<String, dynamic> row);

class DashboardTableDefinition {
  const DashboardTableDefinition({
    required this.title,
    required this.tableKey,
    required this.headers,
    required this.rowBuilder,
    required this.reloadKeySuffix,
  });

  final String title;
  final String tableKey;
  final List<String> headers;
  final DashboardTableRowBuilder rowBuilder;
  final String reloadKeySuffix;
}
