import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/dashboard_query.dart';
import 'dashboard_export_menu.dart';

/// Ações do cabeçalho do dashboard: atualizar + menu único de exportação.
class DashboardHeaderActions extends ConsumerWidget {
  const DashboardHeaderActions({
    super.key,
    required this.onRefresh,
    required this.reportPath,
    required this.query,
    required this.exportEnabled,
    required this.exportSuccessMessage,
  });

  final VoidCallback onRefresh;
  final String reportPath;
  final DashboardQuery query;
  final bool exportEnabled;
  final String exportSuccessMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        DashboardExportMenu(
          reportPath: reportPath,
          query: query,
          enabled: exportEnabled,
          successMessage: exportSuccessMessage,
        ),
      ],
    );
  }
}
