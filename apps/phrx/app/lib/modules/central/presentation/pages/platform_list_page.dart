import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../providers/platform_providers.dart';

/// Página genérica de listagem da plataforma.
class PlatformListPage extends ConsumerWidget {
  const PlatformListPage({
    super.key,
    required this.title,
    required this.subtitle,
    this.invoices = false,
    this.payments = false,
    this.placeholder,
  });

  final String title;
  final String subtitle;
  final bool invoices;
  final bool payments;
  final String? placeholder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (placeholder != null) {
      return EnterpriseModuleHub(
        title: title,
        subtitle: subtitle,
        tag: 'Plataforma',
        child: ModuleEmptyState(
          title: placeholder!,
          subtitle: 'Funcionalidade preparada para integração com a API central.',
        ),
      );
    }

    if (invoices) {
      final async = ref.watch(platformInvoicesProvider);
      return EnterpriseModuleHub(
        title: title,
        subtitle: subtitle,
        tag: 'Plataforma',
        child: async.when(
          loading: () => const ModuleLoadingState(),
          error: (e, _) => ModuleErrorState(
            title: 'Erro',
            message: e.toString(),
            onRetry: () => ref.invalidate(platformInvoicesProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const ModuleEmptyState(title: 'Sem faturas.');
            }
            return EnterpriseDataTable(
              columns: const [
                DataColumn(label: Text('Número')),
                DataColumn(label: Text('Cliente')),
                DataColumn(label: Text('Total')),
                DataColumn(label: Text('Estado')),
              ],
              rowCount: items.length,
              rowBuilder: (context, index) {
                final i = items[index];
                return DataRow(
                  cells: [
                    DataCell(Text(i.number)),
                    DataCell(Text(i.tenantName)),
                    DataCell(Text('${i.total}')),
                    DataCell(EnterpriseStatusChip(label: i.status)),
                  ],
                );
              },
            );
          },
        ),
      );
    }

    if (payments) {
      final async = ref.watch(platformPaymentsProvider);
      return EnterpriseModuleHub(
        title: title,
        subtitle: subtitle,
        tag: 'Plataforma',
        child: async.when(
          loading: () => const ModuleLoadingState(),
          error: (e, _) => ModuleErrorState(
            title: 'Erro',
            message: e.toString(),
            onRetry: () => ref.invalidate(platformPaymentsProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const ModuleEmptyState(title: 'Sem pagamentos.');
            }
            return EnterpriseDataTable(
              columns: const [
                DataColumn(label: Text('Cliente')),
                DataColumn(label: Text('Referência')),
                DataColumn(label: Text('Valor')),
                DataColumn(label: Text('Estado')),
              ],
              rowCount: items.length,
              rowBuilder: (context, index) {
                final p = items[index];
                return DataRow(
                  cells: [
                    DataCell(Text(p.tenantName)),
                    DataCell(Text(p.reference)),
                    DataCell(Text('${p.amount}')),
                    DataCell(EnterpriseStatusChip(label: p.status)),
                  ],
                );
              },
            );
          },
        ),
      );
    }

    return EnterpriseModuleHub(
      title: title,
      subtitle: subtitle,
      tag: 'Plataforma',
      child: const ModuleEmptyState(title: 'Em breve'),
    );
  }
}
