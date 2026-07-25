import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/spacing.dart';
import '../../../../../shared/responsive/pharma_screen_layout.dart';
import '../../domain/entities/invoice_summary.dart';
import '../providers/invoice_detail_provider.dart';
import '../providers/invoice_list_provider.dart';
import 'invoice_pagination.dart';
import 'invoices_results_widgets.dart';
import 'invoices_state_widgets.dart';
import 'invoices_toolbar_and_kpis.dart';

class InvoicesBody extends ConsumerWidget {
  const InvoicesBody({
    super.key,
    required this.searchController,
    required this.listState,
    required this.detailState,
    required this.onView,
    required this.onCancel,
    required this.onPrint,
  });

  final TextEditingController searchController;
  final InvoiceListState listState;
  final InvoiceDetailState detailState;
  final ValueChanged<InvoiceSummary> onView;
  final ValueChanged<InvoiceSummary> onCancel;
  final ValueChanged<InvoiceSummary> onPrint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.spacing;
    final query = listState.query;
    final summary = listState.summary;
    final totalInvoices = summary.total;
    final cancelled = summary.cancelled;
    final paid = summary.paid;
    final pending = summary.pending;

    if (PharmaScreenLayout.isMobile(context)) {
      return InvoicesMobileContent(
        searchController: searchController,
        listState: listState,
        detailState: detailState,
        totalInvoices: totalInvoices,
        paid: paid,
        pending: pending,
        cancelled: cancelled,
        onView: onView,
        onCancel: onCancel,
        onPrint: onPrint,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InvoicesToolbarV2(
          searchController: searchController,
          state: listState,
        ),
        SizedBox(height: s.md),
        InvoicesKpiGrid(
          totalInvoices: totalInvoices,
          paid: paid,
          pending: pending,
          cancelled: cancelled,
          hasFilters: query.hasFilters,
        ),
        SizedBox(height: s.md),
        if (listState.showingCachedData || listState.errorMessage != null)
          InvoicesInfoBanner(state: listState),
        SizedBox(height: s.md),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: switch (listState.viewState) {
              InvoiceViewState.loading => const InvoicesLoadingSkeleton(),
              InvoiceViewState.updating => Stack(
                  children: [
                    InvoicesResults(
                      invoices: listState.items,
                      onView: onView,
                      onCancel: onCancel,
                      onPrint: onPrint,
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: LinearProgressIndicator(minHeight: s.xxs),
                    ),
                  ],
                ),
              InvoiceViewState.error => InvoicesErrorState(
                  message: listState.errorMessage ?? 'Falha ao carregar faturas.',
                  onRetry: () => ref.read(invoiceListProvider.notifier).refresh(),
                ),
              InvoiceViewState.empty => InvoicesEmptyState(
                  onClearFilters: query.hasFilters
                      ? () => ref.read(invoiceListProvider.notifier).clearFilters()
                      : null,
                ),
              _ => InvoicesResults(
                  invoices: listState.items,
                  onView: onView,
                  onCancel: onCancel,
                  onPrint: onPrint,
                ),
            },
          ),
        ),
        SizedBox(height: s.md),
        InvoicePagination(
          page: query.page,
          pageSize: query.pageSize,
          hasMore: listState.hasMore,
          isBusy: listState.isBusy,
          onPrev: query.page > 1
              ? () => ref.read(invoiceListProvider.notifier).goToPage(query.page - 1)
              : null,
          onNext: listState.hasMore
              ? () => ref.read(invoiceListProvider.notifier).goToPage(query.page + 1)
              : null,
          onPageSizeChanged: (value) =>
              ref.read(invoiceListProvider.notifier).setPageSize(value),
        ),
        if (detailState.hasSelection) const SizedBox.shrink(),
      ],
    );
  }
}

class InvoicesMobileContent extends ConsumerWidget {
  const InvoicesMobileContent({
    super.key,
    required this.searchController,
    required this.listState,
    required this.detailState,
    required this.totalInvoices,
    required this.paid,
    required this.pending,
    required this.cancelled,
    required this.onView,
    required this.onCancel,
    required this.onPrint,
  });

  final TextEditingController searchController;
  final InvoiceListState listState;
  final InvoiceDetailState detailState;
  final int totalInvoices;
  final int paid;
  final int pending;
  final int cancelled;
  final ValueChanged<InvoiceSummary> onView;
  final ValueChanged<InvoiceSummary> onCancel;
  final ValueChanged<InvoiceSummary> onPrint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.spacing;
    final query = listState.query;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: InvoicesToolbarV2(
            searchController: searchController,
            state: listState,
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: s.md)),
        SliverToBoxAdapter(
          child: InvoicesKpiGrid(
            totalInvoices: totalInvoices,
            paid: paid,
            pending: pending,
            cancelled: cancelled,
            hasFilters: query.hasFilters,
          ),
        ),
        if (listState.showingCachedData || listState.errorMessage != null) ...[
          SliverToBoxAdapter(child: SizedBox(height: s.md)),
          SliverToBoxAdapter(child: InvoicesInfoBanner(state: listState)),
        ],
        SliverToBoxAdapter(child: SizedBox(height: s.md)),
        SliverToBoxAdapter(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: switch (listState.viewState) {
              InvoiceViewState.loading => const InvoicesLoadingSkeleton(embedded: true),
              InvoiceViewState.updating => Stack(
                  children: [
                    InvoicesResults(
                      invoices: listState.items,
                      onView: onView,
                      onCancel: onCancel,
                      onPrint: onPrint,
                      searchController: searchController,
                      embedded: true,
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: LinearProgressIndicator(minHeight: s.xxs),
                    ),
                  ],
                ),
              InvoiceViewState.error => InvoicesErrorState(
                  message: listState.errorMessage ?? 'Falha ao carregar faturas.',
                  onRetry: () => ref.read(invoiceListProvider.notifier).refresh(),
                ),
              InvoiceViewState.empty => InvoicesEmptyState(
                  onClearFilters: query.hasFilters
                      ? () => ref.read(invoiceListProvider.notifier).clearFilters()
                      : null,
                ),
              _ => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InvoicesResults(
                      invoices: listState.items,
                      onView: onView,
                      onCancel: onCancel,
                      onPrint: onPrint,
                      searchController: searchController,
                      embedded: true,
                    ),
                    SizedBox(height: s.md),
                    InvoicePagination(
                      page: query.page,
                      pageSize: query.pageSize,
                      hasMore: listState.hasMore,
                      isBusy: listState.isBusy,
                      onPrev: query.page > 1
                          ? () => ref.read(invoiceListProvider.notifier).goToPage(query.page - 1)
                          : null,
                      onNext: listState.hasMore
                          ? () => ref.read(invoiceListProvider.notifier).goToPage(query.page + 1)
                          : null,
                      onPageSizeChanged: (value) =>
                          ref.read(invoiceListProvider.notifier).setPageSize(value),
                    ),
                    if (detailState.hasSelection) const SizedBox.shrink(),
                  ],
                ),
            },
          ),
        ),
      ],
    );
  }
}
