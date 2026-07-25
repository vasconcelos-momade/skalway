import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../reports/presentation/controllers/report_controller.dart';
import '../../domain/entities/audit_entities.dart';

Map<String, dynamic> auditReportQuery(Map<String, dynamic> params) {
  final query = <String, dynamic>{};
  params.forEach((key, value) {
    if (value == null) return;
    if (value is String && value.isEmpty) return;
    query[key] = value;
  });
  return query;
}

Map<String, dynamic> auditReportQueryFromAuditQuery(
  AuditQuery query, {
  bool useType = false,
}) {
  return auditReportQuery(<String, dynamic>{
    if (query.search.trim().isNotEmpty) 'q': query.search.trim(),
    if (query.entity != null) 'entity': query.entity,
    if (!useType && query.action != null) 'action': query.action,
    if (useType && query.type != null) 'type': query.type,
    if (query.dateFrom != null) 'dateFrom': formatAuditReportDate(query.dateFrom!),
    if (query.dateTo != null) 'dateTo': formatAuditReportDate(query.dateTo!),
  });
}

List<Widget> auditReportActions({
  required WidgetRef ref,
  required bool enabled,
  required String path,
  required Map<String, dynamic> queryParameters,
}) {
  final reportState = ref.watch(reportControllerProvider);
  final reportController = ref.read(reportControllerProvider.notifier);
  final isBusy = !enabled || reportState.isSubmitting;
  final query = auditReportQuery(queryParameters);

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

Widget? auditReportError(WidgetRef ref) {
  final message = ref.watch(reportControllerProvider).errorMessage;
  if (message == null) return null;
  return Text(message);
}

String formatAuditReportDate(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
