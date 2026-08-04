import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/design_tokens.dart';
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
      final busy = ref.watch(platformBillingActionsProvider);
      final currency = NumberFormat.currency(symbol: 'MT ', decimalDigits: 0);
      final dateFmt = DateFormat('dd/MM/yyyy');

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
                DataColumn(label: Text('Período')),
                DataColumn(label: Text('Plano')),
                DataColumn(label: Text('Base')),
                DataColumn(label: Text('Extras')),
                DataColumn(label: Text('Total')),
                DataColumn(label: Text('Estado')),
                DataColumn(label: Text('Vencimento')),
                DataColumn(label: Text('')),
              ],
              rowCount: items.length,
              rowBuilder: (context, index) {
                final i = items[index];
                return DataRow(
                  cells: [
                    DataCell(Text(i.number)),
                    DataCell(Text(i.period)),
                    DataCell(Text(i.planName)),
                    DataCell(
                      Text(
                        i.planMonthlyPrice == null
                            ? '—'
                            : currency.format(i.planMonthlyPrice),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${i.extraBranches ?? 0} × '
                        '${i.extraBranchPrice == null ? '—' : currency.format(i.extraBranchPrice)}',
                      ),
                    ),
                    DataCell(Text(currency.format(i.total))),
                    DataCell(
                      EnterpriseStatusChip(
                        label: _invoiceStatusLabel(i.status),
                        color: _invoiceStatusColor(context, i.status),
                      ),
                    ),
                    DataCell(
                      Text(
                        i.dueDate == null
                            ? '—'
                            : dateFmt.format(i.dueDate!.toLocal()),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        tooltip: 'PDF',
                        onPressed: busy
                            ? null
                            : () => ref
                                .read(platformBillingActionsProvider.notifier)
                                .downloadInvoicePdf(
                                  tenantId: i.tenantId,
                                  invoiceId: i.id,
                                  fileName: 'fatura-${i.number}.pdf',
                                ),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                      ),
                    ),
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

String _invoiceStatusLabel(String raw) {
  switch (raw.toLowerCase()) {
    case 'pendente':
      return 'Pendente';
    case 'parcial':
      return 'Parcial';
    case 'pago':
    case 'paga':
      return 'Paga';
    case 'vencido':
    case 'vencida':
      return 'Vencida';
    case 'cancelado':
    case 'cancelada':
      return 'Cancelada';
    default:
      return raw.toUpperCase();
  }
}

Color? _invoiceStatusColor(BuildContext context, String raw) {
  final tokens = context.pharmaTokens;
  switch (raw.toLowerCase()) {
    case 'pago':
    case 'paga':
      return tokens.posSuccess;
    case 'parcial':
    case 'pendente':
      return tokens.posWarning;
    case 'vencido':
    case 'vencida':
    case 'cancelado':
    case 'cancelada':
      return tokens.posDanger;
    default:
      return null;
  }
}
