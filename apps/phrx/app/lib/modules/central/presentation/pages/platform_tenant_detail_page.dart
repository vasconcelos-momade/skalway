import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/layout/enterprise_tab_hub.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../domain/entities/platform_entities.dart';
import '../providers/platform_providers.dart';
import '../widgets/create_branch_form_dialog.dart';

class PlatformTenantDetailPage extends ConsumerWidget {
  const PlatformTenantDetailPage({super.key, required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(platformTenantDetailProvider(tenantId));
    final currency = NumberFormat.currency(symbol: 'MT ', decimalDigits: 0);
    final dateFmt = DateFormat('dd/MM/yyyy');

    return async.when(
      loading: () => const EnterpriseModuleHub(
        title: 'Tenant',
        tag: 'Plataforma',
        child: ModuleLoadingState(),
      ),
      error: (e, _) => EnterpriseModuleHub(
        title: 'Tenant',
        tag: 'Plataforma',
        child: ModuleErrorState(
          title: 'Erro',
          message: e.toString(),
          onRetry: () => invalidateTenantBilling(ref, tenantId),
        ),
      ),
      data: (detail) {
        final t = detail.summary;
        final sub = detail.subscription;
        final nextAmount =
            sub?.estimatedMonthlyTotal ?? sub?.monthlyPrice ?? t.monthlyValue ?? 0;
        return EnterpriseModuleHub(
          title: t.companyName,
          subtitle: '${t.tenantName} • ${_statusLabel(t.status)}',
          tag: 'Plataforma',
          actions: [
            IconButton(
              tooltip: 'Actualizar',
              onPressed: () => invalidateTenantBilling(ref, tenantId),
              icon: const Icon(Icons.refresh),
            ),
          ],
          kpis: [
            EnterpriseStatCard(
              title: 'Plano',
              value: sub?.planName ?? t.planName ?? '—',
              icon: Icons.layers_outlined,
            ),
            EnterpriseStatCard(
              title: 'Próxima factura',
              value: currency.format(nextAmount),
              icon: Icons.payments_outlined,
              accent: StatCardAccent.info,
            ),
            EnterpriseStatCard(
              title: 'Filiais activas',
              value: '${sub?.activeBranches ?? detail.branches.where((b) => b.active).length}',
              icon: Icons.store_outlined,
            ),
            EnterpriseStatCard(
              title: 'Extras',
              value: '${sub?.extraBranches ?? 0}',
              icon: Icons.add_business_outlined,
              accent: (sub?.extraBranches ?? 0) > 0
                  ? StatCardAccent.warning
                  : StatCardAccent.neutral,
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (sub != null && sub.isTrial)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TrialBanner(
                    subscription: sub,
                    currency: currency,
                    dateFmt: dateFmt,
                    tenantId: tenantId,
                  ),
                ),
              Expanded(
                child: EnterpriseTabHub(
                  compact: true,
                  tabs: [
                    EnterpriseTabHubTab(
                      label: 'Assinatura',
                      icon: Icons.card_membership_outlined,
                      body: _SubscriptionTab(
                        subscription: sub,
                        currency: currency,
                        dateFmt: dateFmt,
                      ),
                    ),
                    EnterpriseTabHubTab(
                      label: 'Filiais',
                      icon: Icons.store_outlined,
                      body: _BranchesTab(
                        tenantId: tenantId,
                        branches: detail.branches,
                      ),
                    ),
                    EnterpriseTabHubTab(
                      label: 'Histórico',
                      icon: Icons.history,
                      body: _BranchHistoryTab(tenantId: tenantId),
                    ),
                    EnterpriseTabHubTab(
                      label: 'Faturas',
                      icon: Icons.receipt_long_outlined,
                      body: _InvoicesTab(
                        tenantId: tenantId,
                        currency: currency,
                        dateFmt: dateFmt,
                      ),
                    ),
                    EnterpriseTabHubTab(
                      label: 'Pagamentos',
                      icon: Icons.payments_outlined,
                      body: _PaymentsTab(tenantId: tenantId),
                    ),
                    EnterpriseTabHubTab(
                      label: 'Resumo',
                      icon: Icons.dashboard_outlined,
                      body: _SummaryTab(detail: detail, currency: currency),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _statusLabel(String raw) {
  switch (raw.toLowerCase()) {
    case 'trial':
      return 'Trial';
    case 'ativo':
    case 'active':
      return 'Activo';
    case 'suspenso':
    case 'suspended':
      return 'Suspenso';
    case 'expirado':
    case 'expired':
      return 'Expirado';
    case 'cancelado':
      return 'Cancelado';
    case 'grace':
      return 'Período de graça';
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
    case 'confirmado':
      return 'Confirmado';
    default:
      return raw.toUpperCase();
  }
}

Color? _statusColor(BuildContext context, String raw) {
  final t = context.pharmaTokens;
  switch (raw.toLowerCase()) {
    case 'trial':
      return t.posInfo;
    case 'ativo':
    case 'active':
    case 'pago':
    case 'paga':
    case 'confirmado':
      return t.posSuccess;
    case 'grace':
    case 'parcial':
    case 'pendente':
      return t.posWarning;
    case 'suspenso':
    case 'expirado':
    case 'vencido':
    case 'vencida':
    case 'cancelado':
    case 'falhado':
      return t.posDanger;
    default:
      return null;
  }
}

class _TrialBanner extends ConsumerWidget {
  const _TrialBanner({
    required this.subscription,
    required this.currency,
    required this.dateFmt,
    required this.tenantId,
  });

  final PlatformSubscription subscription;
  final NumberFormat currency;
  final DateFormat dateFmt;
  final String tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final ends = subscription.trialEndsAt;
    final amount = subscription.pendingTrialInvoiceAmount ??
        subscription.estimatedMonthlyTotal ??
        subscription.monthlyPrice ??
        0;

    return Material(
      color: t.posInfo.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(t.radiusMd),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timelapse, color: t.posInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Está a utilizar o Trial',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: t.posInfo,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                EnterpriseStatusChip(
                  label: 'TRIAL',
                  color: t.posInfo,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ends == null
                  ? 'O Trial está activo.'
                  : 'O Trial termina em: ${dateFmt.format(ends.toLocal())}. '
                      'A primeira factura vencerá nessa data.',
            ),
            const SizedBox(height: 4),
            Text('Valor previsto: ${currency.format(amount)}'),
            if (subscription.pendingTrialInvoiceId != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () {
                    // Foco na tab Faturas — o pagamento é registado via API de pagamentos.
                    PharmaFeedback.info(
                      context,
                      'Consulte a fatura ${subscription.lastInvoiceNumber ?? ''} '
                      'no separador Faturas / Pagamentos para liquidar.',
                    );
                    ref.invalidate(platformTenantInvoicesProvider(tenantId));
                  },
                  icon: const Icon(Icons.payment_outlined),
                  label: const Text('Pagar Agora'),
                ),
              ),
            ],
          ],
        ),
      ),
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
          subtitle: _statusLabel(t.status),
          leading: Icons.info_outline,
          chip: EnterpriseStatusChip(
            label: _statusLabel(t.status),
            color: _statusColor(context, t.status),
          ),
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

class _SubscriptionTab extends StatelessWidget {
  const _SubscriptionTab({
    required this.subscription,
    required this.currency,
    required this.dateFmt,
  });

  final PlatformSubscription? subscription;
  final NumberFormat currency;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    if (subscription == null) {
      return const ModuleEmptyState(title: 'Sem subscrição activa.');
    }
    final s = subscription!;
    final next = s.estimatedNextInvoice;
    final nextDate = s.nextBillingAt;

    return ListView(
      children: [
        EnterpriseListCard(
          title: 'Plano actual',
          subtitle: s.planName,
          leading: Icons.layers_outlined,
          chip: EnterpriseStatusChip(
            label: _statusLabel(s.status),
            color: _statusColor(context, s.status),
          ),
        ),
        EnterpriseListCard(
          title: 'Preço base',
          subtitle: currency.format(s.monthlyPrice ?? 0),
          leading: Icons.sell_outlined,
        ),
        EnterpriseListCard(
          title: 'Filiais incluídas',
          subtitle: '${s.includedBranches}',
          leading: Icons.store_outlined,
        ),
        EnterpriseListCard(
          title: 'Filiais activas',
          subtitle: '${s.activeBranches}',
          leading: Icons.storefront_outlined,
        ),
        EnterpriseListCard(
          title: 'Filiais extras',
          subtitle: '${s.extraBranches}',
          leading: Icons.add_business_outlined,
        ),
        EnterpriseListCard(
          title: 'Preço por filial extra',
          subtitle: currency.format(s.extraBranchPrice ?? 0),
          leading: Icons.price_change_outlined,
        ),
        EnterpriseListCard(
          title: 'Próxima renovação',
          subtitle: nextDate == null
              ? '—'
              : dateFmt.format(nextDate.toLocal()),
          leading: Icons.event_outlined,
        ),
        EnterpriseListCard(
          title: 'Valor estimado da próxima factura',
          subtitle: next == null
              ? currency.format(s.estimatedMonthlyTotal ?? s.monthlyPrice ?? 0)
              : '${currency.format(next.planMonthlyPrice)}'
                  '${next.extraBranches > 0 ? ' + ${currency.format(next.extraBranchesCharge)}' : ''}'
                  ' = ${currency.format(next.amount)}',
          leading: Icons.calculate_outlined,
        ),
        if (s.lastInvoiceNumber != null)
          EnterpriseListCard(
            title: 'Última factura',
            subtitle:
                '${s.lastInvoiceNumber} • ${_statusLabel(s.lastInvoiceStatus ?? '')}'
                '${s.lastInvoiceAmount != null ? ' • ${currency.format(s.lastInvoiceAmount)}' : ''}',
            leading: Icons.receipt_outlined,
            chip: s.lastInvoiceStatus == null
                ? null
                : EnterpriseStatusChip(
                    label: _statusLabel(s.lastInvoiceStatus!),
                    color: _statusColor(context, s.lastInvoiceStatus!),
                  ),
          ),
        if (s.trialEndsAt != null)
          EnterpriseListCard(
            title: 'Fim do trial',
            subtitle: dateFmt.format(s.trialEndsAt!.toLocal()),
            leading: Icons.hourglass_bottom,
          ),
      ],
    );
  }
}

class _BranchesTab extends ConsumerWidget {
  const _BranchesTab({required this.tenantId, required this.branches});

  final String tenantId;
  final List<PlatformBranch> branches;

  Future<void> _createBranch(BuildContext context, WidgetRef ref) async {
    final created = await showCreateBranchFormDialog(
      context,
      tenantId: tenantId,
    );
    if (created == null || !context.mounted) return;
    PharmaFeedback.success(
      context,
      'Filial ${created.code} criada. Extras serão cobrados na próxima renovação.',
    );
  }

  Future<void> _deactivate(
    BuildContext context,
    WidgetRef ref,
    PlatformBranch branch,
  ) async {
    final confirmed = await PharmaFeedback.confirm(
      context: context,
      title: 'Desactivar filial',
      message:
          'A filial "${branch.name}" será desactivada imediatamente e deixará '
          'de ser cobrada na próxima renovação.',
      confirmText: 'Desactivar',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(platformBillingActionsProvider.notifier).deactivateBranch(
            tenantId: tenantId,
            branchId: branch.id,
            reason: 'Desactivação via painel Central',
          );
      if (!context.mounted) return;
      PharmaFeedback.success(context, 'Filial desactivada.');
    } catch (e) {
      if (!context.mounted) return;
      PharmaFeedback.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(platformBillingActionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: busy ? null : () => _createBranch(context, ref),
            icon: const Icon(Icons.add_business_outlined),
            label: const Text('Nova filial'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A criação nunca é bloqueada pelo limite do plano. '
          'Filiais extras entram na próxima factura.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (branches.isEmpty)
          const Expanded(
            child: ModuleEmptyState(title: 'Sem filiais registadas.'),
          )
        else
          Expanded(
            child: EnterpriseDataTable(
              columns: const [
                DataColumn(label: Text('Nome')),
                DataColumn(label: Text('Código')),
                DataColumn(label: Text('Tipo')),
                DataColumn(label: Text('Estado')),
                DataColumn(label: Text('')),
              ],
              rowCount: branches.length,
              rowBuilder: (context, index) {
                final b = branches[index];
                return DataRow(
                  cells: [
                    DataCell(Text(b.name)),
                    DataCell(Text(b.code)),
                    DataCell(Text(b.isHeadOffice ? 'Matriz' : 'Filial')),
                    DataCell(
                      EnterpriseStatusChip(
                        label: b.active ? 'Activa' : 'Inactiva',
                        color: _statusColor(
                          context,
                          b.active ? 'ativo' : 'suspenso',
                        ),
                      ),
                    ),
                    DataCell(
                      b.isHeadOffice || !b.active
                          ? const SizedBox.shrink()
                          : TextButton(
                              onPressed: busy
                                  ? null
                                  : () => _deactivate(context, ref, b),
                              child: const Text('Desactivar'),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

class _BranchHistoryTab extends ConsumerWidget {
  const _BranchHistoryTab({required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(platformTenantBranchHistoryProvider(tenantId));
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return async.when(
      loading: () => const ModuleLoadingState(itemCount: 3),
      error: (e, _) => ModuleErrorState(
        title: 'Erro',
        message: e.toString(),
        onRetry: () =>
            ref.invalidate(platformTenantBranchHistoryProvider(tenantId)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const ModuleEmptyState(
            title: 'Sem histórico de filiais.',
          );
        }
        return EnterpriseDataTable(
          columns: const [
            DataColumn(label: Text('Data')),
            DataColumn(label: Text('Acção')),
            DataColumn(label: Text('Filial')),
            DataColumn(label: Text('Utilizador')),
            DataColumn(label: Text('Motivo')),
          ],
          rowCount: items.length,
          rowBuilder: (context, index) {
            final h = items[index];
            return DataRow(
              cells: [
                DataCell(Text(dateFmt.format(h.effectiveDate.toLocal()))),
                DataCell(
                  EnterpriseStatusChip(
                    label: h.action,
                    color: h.action == 'ADD'
                        ? _statusColor(context, 'ativo')
                        : _statusColor(context, 'suspenso'),
                  ),
                ),
                DataCell(
                  Text(
                    [
                      if (h.branchName != null) h.branchName!,
                      if (h.branchCode != null) '(${h.branchCode})',
                    ].join(' '),
                  ),
                ),
                DataCell(Text(h.createdByName ?? h.createdByEmail ?? '—')),
                DataCell(Text(h.reason ?? '—')),
              ],
            );
          },
        );
      },
    );
  }
}

class _InvoicesTab extends ConsumerWidget {
  const _InvoicesTab({
    required this.tenantId,
    required this.currency,
    required this.dateFmt,
  });

  final String tenantId;
  final NumberFormat currency;
  final DateFormat dateFmt;

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
            DataColumn(label: Text('Plano')),
            DataColumn(label: Text('Base')),
            DataColumn(label: Text('Extras')),
            DataColumn(label: Text('Total')),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('Vencimento')),
            DataColumn(label: Text('')),
          ],
          rowCount: invoices.length,
          rowBuilder: (context, index) {
            final i = invoices[index];
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
                    label: _statusLabel(i.status),
                    color: _statusColor(context, i.status),
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
                DataCell(
                  EnterpriseStatusChip(
                    label: _statusLabel(p.status),
                    color: _statusColor(context, p.status),
                  ),
                ),
                DataCell(
                  canConfirm
                      ? TextButton(
                          onPressed: busy
                              ? null
                              : () async {
                                  try {
                                    await ref
                                        .read(
                                          platformBillingActionsProvider
                                              .notifier,
                                        )
                                        .confirmPayment(
                                          tenantId: tenantId,
                                          paymentId: p.id,
                                        );
                                    if (!context.mounted) return;
                                    PharmaFeedback.success(
                                      context,
                                      'Pagamento confirmado.',
                                    );
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
