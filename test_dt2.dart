import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';

void main() {
  var table = DataTable2(
    columns: const [],
    rows: const [],
    dataRowHeight: 60,
    headingRowHeight: 50,
    minWidth: 600,
    fixedTopRows: 1,
  );
}
