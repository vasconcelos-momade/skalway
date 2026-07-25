import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../reports/presentation/controllers/report_controller.dart';
import '../../domain/dashboard_query.dart';
import 'dashboard_widgets.dart';

/// Menu único de exportação (PDF e CSV) para painéis do dashboard.
class DashboardExportMenu extends ConsumerWidget {
  const DashboardExportMenu({
    super.key,
    required this.reportPath,
    required this.query,
    required this.enabled,
    required this.successMessage,
  });

  final String reportPath;
  final DashboardQuery query;
  final bool enabled;
  final String successMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(reportControllerProvider).isSubmitting;

    return PopupMenuButton<String>(
      tooltip: 'Exportar',
      enabled: enabled && !busy,
      icon: const Icon(Icons.file_download_outlined),
      onSelected: (format) async {
        await dashboardReportExport(
          ref: ref,
          path: reportPath,
          query: query,
          format: format,
        );
        if (!context.mounted) return;
        PharmaFeedback.success(context, successMessage);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              Icon(
                Icons.picture_as_pdf_outlined,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              const Text('PDF'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'csv',
          child: Row(
            children: [
              Icon(
                Icons.table_rows_outlined,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              const Text('CSV'),
            ],
          ),
        ),
      ],
    );
  }
}
