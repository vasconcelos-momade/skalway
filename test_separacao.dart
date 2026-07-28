import 'package:flutter/material.dart';

class EnterpriseTableHeader {
  final List<DataColumn> columns;
  const EnterpriseTableHeader({required this.columns});
}

class EnterpriseTableBody extends StatelessWidget {
  final EnterpriseTableHeader header;
  final List<DataRow> rows;
  const EnterpriseTableBody({required this.header, required this.rows});
  
  @override
  Widget build(BuildContext context) {
    return DataTable(columns: header.columns, rows: rows);
  }
}
