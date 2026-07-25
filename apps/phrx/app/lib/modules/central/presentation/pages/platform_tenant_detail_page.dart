import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/layout/enterprise_tab_hub.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../domain/entities/platform_entities.dart';
import '../providers/platform_providers.dart';

class PlatformTenantDetailPage extends ConsumerWidget {
  const PlatformTenantDetailPage({super.key, required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(platformTenantDetailProvider(tenantId));
    final currency = NumberFormat.currency(symbol: 'MT ', decimalDigits: 0);

    return async.when(
      loading: () => const EnterpriseModuleHub(
        title: 'Cliente',
        tag: 'Plataforma',
        child: ModuleLoadingState(),
      ),
      error: (e, _) => EnterpriseModuleHub(
        title: 'Cliente',
        tag: 'Plataforma',
        child: ModuleErrorState(
          title: 'Erro',
          message: e.toString(),
          onRetry: () => ref.invalidate(platformTenantDetailProvider(tenantId)),
        ),
      ),
      data: (detail) {
        final t = detail.summary;
        final sub = detail.subscription;
        return EnterpriseModuleHub(
          title: t.companyName,
          subtitle: '${t.tenantName} • ${t.status.toUpperCase()}',
          tag: 'Plataforma',
          kpis: [
            EnterpriseStatCard(
              title: 'Plano',
              value: sub?.planName ?? t.planName ?? '—',
              icon: Icons.layers_outlined,
            ),
            EnterpriseStatCard(
              title: 'Valor Mensal',
              value: currency.format(sub?.monthlyPrice ?? t.monthlyValue ?? 0),
              icon: Icons.payments_outlined,
            ),
            EnterpriseStatCard(
              title: 'Filiais',
              value: '${detail.branches.length}',
              icon: Icons.store_outlined,
            ),
            EnterpriseStatCard(
              title: 'País',
              value: t.country,
              icon: Icons.flag_outlined,
            ),
          ],
          child: EnterpriseTabHub(
            compact: true,
            tabs: [
              EnterpriseTabHubTab(
                label: 'Resumo',
                icon: Icons.dashboard_outlined,
                body: _SummaryTab(detail: detail, currency: currency),
              ),
              EnterpriseTabHubTab(
                label: 'Filiais',
                icon: Icons.store_outlined,
                body: _BranchesTab(branches: detail.branches),
              ),
              EnterpriseTabHubTab(
                label: 'Assinatura',
                icon: Icons.card_membership_outlined,
                body: _SubscriptionTab(subscription: sub),
              ),
              EnterpriseTabHubTab(
                label: 'Faturas',
                icon: Icons.receipt_long_outlined,
                body: _InvoicesTab(tenantId: tenantId),
              ),
              EnterpriseTabHubTab(
                label: 'Pagamentos',
                icon: Icons.payments_outlined,
                body: _PaymentsTab(tenantId: tenantId),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({required this.detail, required this.currency});

  final PlatformTenantDetail detail;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final t = detail.summary;
    return ListView(
      children: [
        EnterpriseListCard(
          title: 'Empresa',
          subtitle: t.companyName,
          leading: Icons.business_outlined,
        ),
        EnterpriseListCard(
          title: 'Tenant',
          subtitle: t.tenantName,
          leading: Icons.dns_outlined,
        ),
        EnterpriseListCard(
          title: 'Estado',
          subtitle: t.status,
          leading: Icons.info_outline,
          chip: EnterpriseStatusChip(label: t.status),
        ),
        if (detail.walletBalance != null)
          EnterpriseListCard(
            title: 'Saldo Wallet',
            subtitle: currency.format(detail.walletBalance),
            leading: Icons.account_balance_wallet_outlined,
          ),
      ],
    );
  }
}

class _BranchesTab extends StatelessWidget {
  const _BranchesTab({required this.branches});

  final List<PlatformBranch> branches;

  @override
  Widget build(BuildContext context) {
    if (branches.isEmpty) {
      return const ModuleEmptyState(title: 'Sem filiais registadas.');
    }
    return EnterpriseDataTable(
      columns: const [
        DataColumn(label: Text('Nome')),
        DataColumn(label: Text('Código')),
        DataColumn(label: Text('Estado')),
        DataColumn(label: Text('Sync')),
      ],
      rowCount: branches.length,
      rowBuilder: (context, index) {
        final b = branches[index];
        return DataRow(
          cells: [
            DataCell(Text(b.name)),
            DataCell(Text(b.code)),
            DataCell(Text(b.active ? 'Activa' : 'Inactiva')),
            DataCell(Text(b.connectionStatus ?? '—')),
          ],
        );
      },
    );
  }
}

class _SubscriptionTab extends StatelessWidget {
  const _SubscriptionTab({required this.subscription});

  final PlatformSubscription? subscription;

  @override
  Widget build(BuildContext context) {
    if (subscription == null) {
      return const ModuleEmptyState(title: 'Sem subscrição activa.');
    }
    return ListView(
      children: [
        EnterpriseListCard(
          title: 'Plano',
          subtitle: subscription!.planName,
          leading: Icons.layers_outlined,
        ),
        EnterpriseListCard(
          title: 'Estado',
          subtitle: subscription!.status,
          leading: Icons.verified_outlined,
        ),
        EnterpriseListCard(
          title: 'Filiais incluídas',
          subtitle: '${subscription!.includedBranches}',
          leading: Icons.store_outlined,
        ),
      ],
    );
  }
}

class _InvoicesTab extends ConsumerWidget {
  const _InvoicesTab({required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(platformTenantInvoicesProvider(tenantId));
    final busy = ref.watch(platformBillingActionsProvider);
    return async.when(
      loading: () => const ModuleLoadingState(itemCount: 3),
      error: (e, _) => ModuleErrorState(
        title: 'Erro',
        message: e.toString(),
        onRetry: () => ref.invalidate(platformTenantInvoicesProvider(tenantId)),
      ),
      data: (invoices) {
        if (invoices.isEmpty) {
          return const ModuleEmptyState(title: 'Sem faturas.');
        }
        return EnterpriseDataTable(
          columns: const [
            DataColumn(label: Text('Número')),
            DataColumn(label: Text('Período')),
            DataColumn(label: Text('Total')),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('')),
          ],
          rowCount: invoices.length,
          rowBuilder: (context, index) {
            final i = invoices[index];
            return DataRow(
              cells: [
                DataCell(Text(i.number)),
                DataCell(Text(i.period)),
                DataCell(Text('${i.total}')),
                DataCell(EnterpriseStatusChip(label: i.status)),
                DataCell(
                  IconButton(
                    tooltip: 'PDF',
                    onPressed: busy
                        ? null
                        : () => ref
                            .read(platformBillingActionsProvider.notifier)
                            .downloadInvoicePdf(
                              tenantId: tenantId,
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
    );
  }
}

class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab({required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(platformTenantPaymentsProvider(tenantId));
    final busy = ref.watch(platformBillingActionsProvider);
    return async.when(
      loading: () => const ModuleLoadingState(itemCount: 3),
      error: (e, _) => ModuleErrorState(
        title: 'Erro',
        message: e.toString(),
        onRetry: () => ref.invalidate(platformTenantPaymentsProvider(tenantId)),
      ),
      data: (payments) {
        if (payments.isEmpty) {
          return const ModuleEmptyState(title: 'Sem pagamentos.');
        }
        return EnterpriseDataTable(
          columns: const [
            DataColumn(label: Text('Referência')),
            DataColumn(label: Text('Valor')),
            DataColumn(label: Text('Método')),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('')),
          ],
          rowCount: payments.length,
          rowBuilder: (context, index) {
            final p = payments[index];
            final canConfirm = p.status.toLowerCase() == 'pendente';
            return DataRow(
              cells: [
                DataCell(Text(p.reference)),
                DataCell(Text('${p.amount}')),
                DataCell(Text(p.method)),
                DataCell(EnterpriseStatusChip(label: p.status)),
                DataCell(
                  canConfirm
                      ? TextButton(
                          onPressed: busy
                              ? null
                              : () async {
                                  try {
                                    await ref
                                        .read(platformBillingActionsProvider
                                            .notifier)
                                        .confirmPayment(
                                          tenantId: tenantId,
                                          paymentId: p.id,
                                        );
                                    if (!context.mounted) return;
                                    PharmaFeedback.success(context, 'Pagamento confirmado.');
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    PharmaFeedback.error(context, 'Erro: $e');
                                  }
                                },
                          child: const Text('Aprovar'),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
