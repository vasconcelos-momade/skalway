import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/refresh/page_refresh.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../../domain/entities/platform_entities.dart';
import '../providers/platform_providers.dart';

/// Página genérica de listagem da plataforma (placeholders / pagamentos).
class PlatformListPage extends ConsumerStatefulWidget {
  const PlatformListPage({
    super.key,
    required this.title,
    required this.subtitle,
    this.payments = false,
    this.placeholder,
  });

  final String title;
  final String subtitle;
  final bool payments;
  final String? placeholder;

  @override
  ConsumerState<PlatformListPage> createState() => _PlatformListPageState();
}

class _PlatformListPageState extends ConsumerState<PlatformListPage> {
  final _searchCtrl = TextEditingController();
  final List<PlatformPayment> _accumulated = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.placeholder != null) {
      return EnterpriseModuleHub(
        title: widget.title,
        subtitle: widget.subtitle,
        tag: 'Plataforma',
        child: ModuleEmptyState(
          title: widget.placeholder!,
          subtitle:
              'Funcionalidade preparada para integração com a API central.',
        ),
      );
    }

    if (!widget.payments) {
      return EnterpriseModuleHub(
        title: widget.title,
        subtitle: widget.subtitle,
        tag: 'Plataforma',
        child: const ModuleEmptyState(title: 'Em breve'),
      );
    }

    final async = ref.watch(platformPaymentsProvider);
    final notifier = ref.read(platformPaymentsProvider.notifier);
    final currency = NumberFormat.currency(symbol: 'MT ', decimalDigits: 2);

    if (_searchCtrl.text != notifier.search) {
      _searchCtrl.value = TextEditingValue(
        text: notifier.search,
        selection: TextSelection.collapsed(offset: notifier.search.length),
      );
    }

    ref.listen(platformPaymentsProvider, (previous, next) {
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
            title: widget.title,
            subtitle: widget.subtitle,
            tag: 'Plataforma',
            child: async.when(
              loading: () => _accumulated.isEmpty
                  ? const ModuleLoadingState()
                  : _buildPayments(
                      context,
                      isMobile: isMobile,
                      items: _accumulated,
                      page: pageData?.page ?? notifier.page,
                      pageSize: pageData?.pageSize ?? notifier.pageSize,
                      hasMore: pageData?.hasMore ?? false,
                      totalCount: pageData?.totalCount,
                      isLoading: true,
                      currency: currency,
                      notifier: notifier,
                    ),
              error: (e, _) => _accumulated.isEmpty
                  ? ModuleErrorState(
                      title: 'Erro',
                      message: e.toString(),
                      onRetry: () => notifier.refresh(),
                    )
                  : _buildPayments(
                      context,
                      isMobile: isMobile,
                      items: _accumulated,
                      page: notifier.page,
                      pageSize: notifier.pageSize,
                      hasMore: false,
                      totalCount: null,
                      isLoading: false,
                      errorText: e.toString(),
                      currency: currency,
                      notifier: notifier,
                    ),
              data: (page) => _buildPayments(
                context,
                isMobile: isMobile,
                items: isMobile ? _accumulated : page.items,
                page: page.page,
                pageSize: page.pageSize,
                hasMore: page.hasMore,
                totalCount: page.totalCount,
                isLoading: false,
                currency: currency,
                notifier: notifier,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPayments(
    BuildContext context, {
    required bool isMobile,
    required List<PlatformPayment> items,
    required int page,
    required int pageSize,
    required bool hasMore,
    required int? totalCount,
    required bool isLoading,
    required NumberFormat currency,
    required PlatformPaymentsNotifier notifier,
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
        searchHint: 'Pesquisar referência, tenant ou fatura…',
        onSearchChanged: notifier.setSearch,
        isLoading: isLoading,
        errorMessage: errorText,
        errorTitle: 'Erro ao carregar pagamentos',
        onRetry: () => notifier.refresh(),
        emptyTitle: 'Sem pagamentos.',
        columns: const [
          DataColumn(label: Text('Cliente')),
          DataColumn(label: Text('Fatura')),
          DataColumn(label: Text('Referência')),
          DataColumn(label: Text('Método')),
          DataColumn(label: Text('Valor')),
          DataColumn(label: Text('Estado')),
        ],
        rowCount: items.length,
        rowBuilder: (context, index) {
          final p = items[index];
          return DataRow(
            cells: [
              DataCell(Text(p.tenantName)),
              DataCell(Text(p.invoiceNumber)),
              DataCell(Text(p.reference)),
              DataCell(Text(p.method)),
              DataCell(Text(currency.format(p.amount))),
              DataCell(
                EnterpriseStatusChip(
                  label: p.status,
                  color: _paymentStatusColor(context, p.status),
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
                itemLabel: 'pagamentos',
                onPageChanged: notifier.goToPage,
                onPageSizeChanged: notifier.setPageSize,
              )
            : null,
      ),
      mobileList: EnterpriseMobileScrollList(
        stickyHeader: EnterpriseMobileToolbar(
          searchController: _searchCtrl,
          searchHint: 'Pesquisar referência, tenant ou fatura…',
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
        emptyMessage: 'Sem pagamentos.',
        onLoadMore:
            hasMore && !isLoading ? () => notifier.goToPage(page + 1) : null,
        itemBuilder: (context, index) {
          final p = items[index];
          return Column(
            children: [
              if (index > 0) const EnterpriseListDivider(),
              EnterpriseListCard(
                title: p.reference,
                subtitle: p.tenantName,
                chip: EnterpriseStatusChip(
                  label: p.status,
                  color: _paymentStatusColor(context, p.status),
                ),
                metadata: [
                  EnterpriseListCardMeta(label: p.invoiceNumber),
                  EnterpriseListCardMeta(
                    label: currency.format(p.amount),
                    emphasized: true,
                  ),
                  EnterpriseListCardMeta(label: p.method),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

Color? _paymentStatusColor(BuildContext context, String status) {
  final tokens = context.pharmaTokens;
  switch (status.toLowerCase()) {
    case 'confirmado':
    case 'pago':
      return tokens.posSuccess;
    case 'pendente':
      return tokens.posWarning;
    case 'falhado':
    case 'cancelado':
      return tokens.posDanger;
    default:
      return null;
  }
}
