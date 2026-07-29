import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/component_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../reports/presentation/controllers/report_controller.dart';
import '../../../../shared/widgets/menus/enterprise_dropdown_menu.dart';

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

  return [
    _EnterpriseExportButton(
      enabled: !isBusy,
      label: buttonLabel,
      isIconButton: isIconButton,
      expandChild: expandChild,
      onPdf: () =>
          reportController.downloadPdf(path: path, queryParameters: query),
      onCsv: () =>
          reportController.exportCsv(path: path, queryParameters: query),
    ),
  ];
}

Widget? pharmacyReportError(WidgetRef ref) {
  final message = ref.watch(reportControllerProvider).errorMessage;
  if (message == null) return null;
  return Text(message);
}

/// Botão Exportar com a mesma altura compacta do botão Filtros.
class _EnterpriseExportButton extends StatelessWidget {
  const _EnterpriseExportButton({
    required this.enabled,
    required this.label,
    required this.isIconButton,
    required this.expandChild,
    required this.onPdf,
    required this.onCsv,
  });

  final bool enabled;
  final String label;
  final bool isIconButton;
  final bool expandChild;
  final VoidCallback onPdf;
  final VoidCallback onCsv;

  Future<void> _open(BuildContext context, BuildContext anchor) async {
    final selected = await showEnterpriseDropdownMenuFrom<String>(
      context: context,
      anchorContext: anchor,
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
        final Widget trigger;
        if (isIconButton) {
          trigger = IconButton.filledTonal(
            onPressed: enabled ? () => _open(context, anchorContext) : null,
            icon: Icon(Icons.download_outlined, size: t.iconSm),
          );
        } else {
          trigger = OutlinedButton.icon(
            style: compactStyle,
            onPressed: enabled ? () => _open(context, anchorContext) : null,
            icon: Icon(Icons.download_outlined, size: t.iconSm),
            label: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          );
        }

        if (expandChild) {
          return SizedBox(width: double.infinity, child: trigger);
        }
        return trigger;
      },
    );
  }
}
