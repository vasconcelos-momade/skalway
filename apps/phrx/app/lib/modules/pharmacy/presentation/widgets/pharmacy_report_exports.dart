import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../reports/presentation/controllers/report_controller.dart';

Map<String, dynamic> pharmacyReportQuery(Map<String, dynamic> params) {
  final query = <String, dynamic>{};
  params.forEach((key, value) {
    if (value == null) return;
    if (value is String && value.isEmpty) return;
    query[key] = value;
  });
  return query;
}

List<Widget> pharmacyReportActions({
  required WidgetRef ref,
  required bool enabled,
  required String path,
  required Map<String, dynamic> queryParameters,
  bool isIconButton = false,
  bool expandChild = false,
  String buttonLabel = 'Exportar',
}) {
  final reportState = ref.watch(reportControllerProvider);
  final reportController = ref.read(reportControllerProvider.notifier);
  final isBusy = !enabled || reportState.isSubmitting;
  final query = pharmacyReportQuery(queryParameters);

  final trigger = isIconButton
      ? IconButton.filledTonal(
          onPressed: null,
          icon: const Icon(Icons.download_outlined),
        )
      : OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.download_outlined),
          label: Text(
            buttonLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        );

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
        PopupMenuItem<String>(
          value: 'pdf',
          child: Text('Exportar PDF'),
        ),
        PopupMenuItem<String>(
          value: 'csv',
          child: Text('Exportar CSV'),
        ),
      ],
      child: expandChild ? SizedBox(width: double.infinity, child: trigger) : trigger,
    ),
  ];
}

Widget? pharmacyReportError(WidgetRef ref) {
  final message = ref.watch(reportControllerProvider).errorMessage;
  if (message == null) return null;
  return Text(message);
}
