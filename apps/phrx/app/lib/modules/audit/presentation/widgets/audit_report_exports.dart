import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/component_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/menus/enterprise_dropdown_menu.dart';
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
    _CompactExportButton(
      enabled: !isBusy,
      onPdf: () =>
          reportController.downloadPdf(path: path, queryParameters: query),
      onCsv: () =>
          reportController.exportCsv(path: path, queryParameters: query),
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

/// Mesma altura compacta do botão Filtros (Design System).
class _CompactExportButton extends StatelessWidget {
  const _CompactExportButton({
    required this.enabled,
    required this.onPdf,
    required this.onCsv,
  });

  final bool enabled;
  final VoidCallback onPdf;
  final VoidCallback onCsv;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final scheme = Theme.of(context).colorScheme;
    final compactStyle = PharmaComponentTheme.outlined(
      t,
      scheme,
      compact: true,
    );

    return Builder(
      builder: (anchorContext) {
        return OutlinedButton.icon(
          style: compactStyle,
          onPressed: enabled
              ? () async {
                  final selected =
                      await showEnterpriseDropdownMenuFrom<String>(
                    context: context,
                    anchorContext: anchorContext,
                    items: const [
                      EnterpriseDropdownItem(
                        value: 'pdf',
                        label: 'Exportar PDF',
                        icon: Icons.picture_as_pdf_outlined,
                      ),
                      EnterpriseDropdownItem(
                        value: 'csv',
                        label: 'Exportar CSV',
                        icon: Icons.table_chart_outlined,
                      ),
                    ],
                  );
                  if (selected == 'pdf') onPdf();
                  if (selected == 'csv') onCsv();
                }
              : null,
          icon: Icon(Icons.download_outlined, size: t.iconSm),
          label: const Text(
            'Exportar',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        );
      },
    );
  }
}
