import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../reports/presentation/controllers/report_controller.dart';

Map<String, dynamic> stockReportQuery(Map<String, dynamic> params) {
  final query = <String, dynamic>{};
  params.forEach((key, value) {
    if (value == null) return;
    if (value is String && value.isEmpty) return;
    query[key] = value;
  });
  return query;
}

List<Widget> stockReportActions({
  required WidgetRef ref,
  required bool enabled,
  required String path,
  required Map<String, dynamic> queryParameters,
}) {
  final reportState = ref.watch(reportControllerProvider);
  final reportController = ref.read(reportControllerProvider.notifier);
  final isBusy = !enabled || reportState.isSubmitting;
  final query = stockReportQuery(queryParameters);

  return [
    PopupMenuButton<String>(
      enabled: !isBusy,
      tooltip: 'Exportar',
      onSelected: (value) {
        if (value == 'pdf') {
          reportController.downloadPdf(path: path, queryParameters: query);
          return;
        }
        reportController.exportCsv(path: path, queryParameters: query);
      },
      itemBuilder: (context) => const [
        PopupMenuItem<String>(value: 'pdf', child: Text('Exportar PDF')),
        PopupMenuItem<String>(value: 'csv', child: Text('Exportar CSV')),
      ],
      child: OutlinedButton.icon(
        onPressed: null,
        icon: Icon(Icons.download_outlined),
        label: Text('Exportar'),
      ),
    ),
  ];
}

Widget? stockReportError(WidgetRef ref) {
  final message = ref.watch(reportControllerProvider).errorMessage;
  if (message == null) return null;
  return Text(message);
}

String formatReportDate(DateTime value) {
  final year = value.year;
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
