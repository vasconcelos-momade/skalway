import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/refresh/page_refresh.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/menus/enterprise_actions_menu_button.dart';
import '../../../../shared/widgets/menus/enterprise_dropdown_menu.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../../domain/entities/platform_entities.dart';
import '../providers/platform_providers.dart';
import '../widgets/confirm_payment_side_sheet.dart';

/// Página de faturas SaaS da Central.
class PlatformInvoicesPage extends ConsumerStatefulWidget {
  const PlatformInvoicesPage({super.key});

  @override
  ConsumerState<PlatformInvoicesPage> createState() =>
      _PlatformInvoicesPageState();
}

class _PlatformInvoicesPageState extends ConsumerState<PlatformInvoicesPage> {
  final _searchCtrl = TextEditingController();
  final List<PlatformInvoice> _accumulated = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(platformInvoicesProvider);
    final notifier = ref.read(platformInvoicesProvider.notifier);
    final busy = ref.watch(platformBillingActionsProvider);
    final currency = NumberFormat.currency(symbol: 'MT ', decimalDigits: 0);
    final dateFmt = DateFormat('dd/MM/yyyy');

    if (_searchCtrl.text != notifier.search) {
      _searchCtrl.value = TextEditingValue(
        text: notifier.search,
        selection: TextSelection.collapsed(offset: notifier.search.length),
      );
    }

    ref.listen(platformInvoicesProvider, (previous, next) {
      final data = next.asData?.value;
      if (data == null) return;
      final prevData = previous?.asData?.value;
      if (data.page == 1) {
        _accumulated
          ..clear()
          ..addAll(data.items);
      } else if (prevData?.page != data.page) {
        _accumulated.addAll(
          data.items.where((e) => !_accumulated.any((a) => a.id == e.id)),
        );
      }
    });

    final pageData = async.asData?.value;
    if (pageData != null &&
        pageData.page == 1 &&
        _accumulated.isEmpty &&
        pageData.items.isNotEmpty) {
      _accumulated.addAll(pageData.items);
    }

    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = !constraints.isTabletOrWider;

        return PageRefreshBinder(
          onRefresh: () => notifier.refresh(),
          child: EnterpriseModuleHub(
            title: 'Faturas',
            subtitle: 'Faturação SaaS consolidada.',
            tag: 'Plataforma',
            filters: null,
            child: async.when(
              loading: () => _accumulated.isEmpty
                  ? const ModuleLoadingState()
                  : _buildBody(
                      context,
                      isMobile: isMobile,
                      items: _accumulated,
                      page: pageData?.page ?? notifier.page,
                      pageSize: pageData?.pageSize ?? notifier.pageSize,
                      hasMore: pageData?.hasMore ?? false,
                      totalCount: pageData?.totalCount,
                      isLoading: true,
                      busy: busy,
                      currency: currency,
                      dateFmt: dateFmt,
                      notifier: notifier,
                    ),
              error: (e, _) => _accumulated.isEmpty
                  ? ModuleErrorState(
                      title: 'Erro',
                      message: e.toString(),
                      onRetry: () => notifier.refresh(),
                    )
                  : _buildBody(
                      context,
                      isMobile: isMobile,
                      items: _accumulated,
                      page: notifier.page,
                      pageSize: notifier.pageSize,
                      hasMore: false,
                      totalCount: null,
                      isLoading: false,
                      errorText: e.toString(),
                      busy: busy,
                      currency: currency,
                      dateFmt: dateFmt,
                      notifier: notifier,
                    ),
              data: (page) => _buildBody(
                context,
                isMobile: isMobile,
                items: isMobile ? _accumulated : page.items,
                page: page.page,
                pageSize: page.pageSize,
                hasMore: page.hasMore,
                totalCount: page.totalCount,
                isLoading: false,
                busy: busy,
                currency: currency,
                dateFmt: dateFmt,
                notifier: notifier,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required bool isMobile,
    required List<PlatformInvoice> items,
    required int page,
    required int pageSize,
    required bool hasMore,
    required int? totalCount,
    required bool isLoading,
    required bool busy,
    required NumberFormat currency,
    required DateFormat dateFmt,
    required PlatformInvoicesNotifier notifier,
    String? errorText,
  }) {
    return EnterpriseAdaptiveListBody(
      isMobile: isMobile,
      isLoading: isLoading,
      errorText: errorText,
      desktopContent: EnterpriseDataTable(
        adaptive: false,
        showCheckboxColumn: false,
        searchController: _searchCtrl,
        searchHint: 'Pesquisar fatura, tenant…',
        onSearchChanged: notifier.setSearch,
        isLoading: isLoading,
        errorMessage: errorText,
        errorTitle: 'Erro ao carregar faturas',
        onRetry: () => notifier.refresh(),
        emptyTitle: 'Sem faturas.',
        columns: const [
          DataColumn(label: Text('Tenant')),
          DataColumn(label: Text('Número')),
          DataColumn(label: Text('Período')),
          DataColumn(label: Text('Plano')),
          DataColumn(label: Text('Base')),
          DataColumn(label: Text('Extras')),
          DataColumn(label: Text('Desconto')),
          DataColumn(label: Text('Total')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Vencimento')),
          DataColumn(label: Text('Acções')),
        ],
        rowCount: items.length,
        rowBuilder: (context, index) {
          final i = items[index];
          return DataRow(
            cells: [
              DataCell(
                _TenantCell(
                  title: i.tenantName,
                  subtitle: i.companyName,
                ),
              ),
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
              DataCell(Text(_extrasLabel(i, currency))),
              DataCell(Text(currency.format(i.discount))),
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
                _InvoiceActionsMenu(
                  invoice: i,
                  busy: busy,
                ),
              ),
            ],
          );
        },
        pagination: totalCount != null
            ? EnterprisePagination(
                page: page,
                pageSize: pageSize,
                totalCount: totalCount,
                isBusy: isLoading,
                itemLabel: 'faturas',
                onPageChanged: notifier.goToPage,
                onPageSizeChanged: notifier.setPageSize,
              )
            : null,
      ),
      desktopPagination: null,
      mobileList: EnterpriseMobileScrollList(
        stickyHeader: EnterpriseMobileToolbar(
          searchController: _searchCtrl,
          searchHint: 'Pesquisar fatura, tenant…',
          enabled: !isLoading,
          isLoading: isLoading,
          hasFilters: false,
          showFiltersButton: false,
          onSearchSubmitted: notifier.setSearch,
          onOpenFilters: () {},
        ),
        itemCount: items.length,
        hasMore: hasMore,
        isLoading: isLoading,
        emptyMessage: 'Sem faturas.',
        onLoadMore:
            hasMore && !isLoading ? () => notifier.goToPage(page + 1) : null,
        itemBuilder: (context, index) {
          final i = items[index];
          final periodArrow = i.period.replaceAll(' a ', ' → ');
          final extrasValue = i.extrasAmount ??
              ((i.extraBranches ?? 0) > 0 && i.extraBranchPrice != null
                  ? (i.extraBranches! * i.extraBranchPrice!)
                  : null);

          return Column(
            children: [
              if (index > 0) const EnterpriseListDivider(),
              EnterpriseListCard(
                title: i.number,
                subtitle: [
                  i.tenantName,
                  if (i.companyName != null && i.companyName!.trim().isNotEmpty)
                    i.companyName!,
                ].join('\n'),
                actions: _InvoiceActionsMenu(invoice: i, busy: busy),
                chip: EnterpriseStatusChip(
                  label: _invoiceStatusLabel(i.status),
                  color: _invoiceStatusColor(context, i.status),
                ),
                trailingMeta: EnterpriseListCardMeta(
                  label: i.dueDate == null
                      ? 'Sem vencimento'
                      : 'Vence ${dateFmt.format(i.dueDate!.toLocal())}',
                ),
                metadata: [
                  EnterpriseListCardMeta(label: 'Período'),
                  EnterpriseListCardMeta(label: periodArrow),
                  EnterpriseListCardMeta(label: 'Plano'),
                  EnterpriseListCardMeta(label: i.planName),
                  EnterpriseListCardMeta(
                    label:
                        'Base ${i.planMonthlyPrice == null ? '—' : currency.format(i.planMonthlyPrice)}'
                        '  ·  Extras ${extrasValue == null ? '—' : currency.format(extrasValue)}'
                        '  ·  Total ${currency.format(i.total)}',
                    emphasized: true,
                  ),
                  if (i.discount > 0)
                    EnterpriseListCardMeta(
                      label: 'Desconto ${currency.format(i.discount)}',
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

String _extrasLabel(PlatformInvoice i, NumberFormat currency) {
  if (i.extrasAmount != null) {
    return currency.format(i.extrasAmount);
  }
  return '${i.extraBranches ?? 0} × '
      '${i.extraBranchPrice == null ? '—' : currency.format(i.extraBranchPrice)}';
}

class _TenantCell extends StatelessWidget {
  const _TenantCell({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.pharmaTokens;
    final company = subtitle?.trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall,
        ),
        if (company != null && company.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            company,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: tokens.textMuted),
          ),
        ],
      ],
    );
  }
}

enum _InvoiceAction { confirmPayment, downloadPdf }

class _InvoiceActionsMenu extends ConsumerWidget {
  const _InvoiceActionsMenu({
    required this.invoice,
    required this.busy,
  });

  final PlatformInvoice invoice;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = <EnterpriseDropdownItem<_InvoiceAction>>[
      if (invoice.canConfirmPayment)
        const EnterpriseDropdownItem(
          value: _InvoiceAction.confirmPayment,
          label: 'Confirmar Pagamento',
          icon: Icons.verified_outlined,
        ),
      const EnterpriseDropdownItem(
        value: _InvoiceAction.downloadPdf,
        label: 'Descarregar PDF',
        icon: Icons.picture_as_pdf_outlined,
      ),
    ];

    return EnterpriseActionsMenuButton<_InvoiceAction>(
      enabled: !busy && items.isNotEmpty,
      items: items,
      onSelected: (action) async {
        switch (action) {
          case _InvoiceAction.confirmPayment:
            await showConfirmPaymentSideSheet(context, invoice: invoice);
          case _InvoiceAction.downloadPdf:
            try {
              await ref
                  .read(platformBillingActionsProvider.notifier)
                  .downloadInvoicePdf(
                    tenantId: invoice.tenantId,
                    invoiceId: invoice.id,
                    fileName: 'fatura-${invoice.number}.pdf',
                  );
            } catch (e) {
              if (!context.mounted) return;
              PharmaFeedback.error(context, 'Erro: $e');
            }
        }
      },
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
