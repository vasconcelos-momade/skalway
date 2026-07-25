import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers/ui_cache_notifier.dart';
import '../../../../../core/contracts/pagination_response.dart' show PaginationResponse, PaginationSummary;
import '../../../../../core/errors/api_failure.dart';
import '../../data/repositories/invoice_repository_impl.dart';
import '../../domain/entities/invoice_summary.dart';
import '../../services/invoice_cache_policy.dart';

enum InvoiceViewState {
  loading,
  loaded,
  empty,
  error,
  updating,
}

class InvoiceListState {
  const InvoiceListState({
    this.items = const <InvoiceSummary>[],
    this.query = const InvoiceQuery(),
    this.viewState = InvoiceViewState.loading,
    this.errorMessage,
    this.hasMore = false,
    this.isInitialized = false,
    this.showingCachedData = false,
    this.lastSyncedAt,
    this.summary = const PaginationSummary(),
  });

  final List<InvoiceSummary> items;
  final InvoiceQuery query;
  final InvoiceViewState viewState;
  final String? errorMessage;
  final bool hasMore;
  final bool isInitialized;
  final bool showingCachedData;
  final DateTime? lastSyncedAt;
  final PaginationSummary summary;

  bool get isBusy =>
      viewState == InvoiceViewState.loading ||
      viewState == InvoiceViewState.updating;

  InvoiceListState copyWith({
    List<InvoiceSummary>? items,
    InvoiceQuery? query,
    InvoiceViewState? viewState,
    String? errorMessage,
    bool? hasMore,
    bool? isInitialized,
    bool? showingCachedData,
    DateTime? lastSyncedAt,
    PaginationSummary? summary,
    bool clearError = false,
  }) {
    return InvoiceListState(
      items: items ?? this.items,
      query: query ?? this.query,
      viewState: viewState ?? this.viewState,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasMore: hasMore ?? this.hasMore,
      isInitialized: isInitialized ?? this.isInitialized,
      showingCachedData: showingCachedData ?? this.showingCachedData,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      summary: summary ?? this.summary,
    );
  }
}

class InvoiceListController extends Notifier<InvoiceListState> {
  static const _uiCacheKey = 'sales.invoices.query';

  Timer? _debounce;
  int _requestId = 0;

  @override
  InvoiceListState build() {
    ref.onDispose(() => _debounce?.cancel());
    final cachedQuery = ref.read(uiCacheProvider.notifier).get<InvoiceQuery>(_uiCacheKey);
    final initialQuery = cachedQuery ?? const InvoiceQuery();
    Future.microtask(() => fetch(query: initialQuery));
    return InvoiceListState(query: initialQuery);
  }

  void onSearchChanged(String value) {
    final nextQuery = state.query.copyWith(
      search: value.trim(),
      page: 1,
    );
    _setQuery(nextQuery, debounce: true);
  }

  Future<void> setQuickFilter(InvoiceQuickFilter filter) async {
    final now = DateTime.now();
    DateTime? dateFrom;
    DateTime? dateTo;
    String? status;

    switch (filter) {
      case InvoiceQuickFilter.today:
        dateFrom = DateTime(now.year, now.month, now.day);
        dateTo = dateFrom;
        break;
      case InvoiceQuickFilter.week:
        final weekday = now.weekday;
        dateFrom = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: weekday - 1));
        dateTo = DateTime(now.year, now.month, now.day);
        break;
      case InvoiceQuickFilter.month:
        dateFrom = DateTime(now.year, now.month, 1);
        dateTo = DateTime(now.year, now.month + 1, 0);
        break;
      case InvoiceQuickFilter.cancelled:
        status = 'ANULADA';
        break;
      case InvoiceQuickFilter.paid:
        status = 'PAGA';
        break;
      case InvoiceQuickFilter.pending:
        status = 'EMITIDA';
        break;
      case InvoiceQuickFilter.none:
        break;
    }

    final nextQuery = state.query.copyWith(
      page: 1,
      quickFilter: filter,
      status: status,
      dateFrom: dateFrom,
      dateTo: dateTo,
      clearStatus: filter == InvoiceQuickFilter.none ||
          filter == InvoiceQuickFilter.today ||
          filter == InvoiceQuickFilter.week ||
          filter == InvoiceQuickFilter.month,
      clearDateRange: filter == InvoiceQuickFilter.none ||
          filter == InvoiceQuickFilter.cancelled ||
          filter == InvoiceQuickFilter.paid ||
          filter == InvoiceQuickFilter.pending,
    );

    await fetch(query: nextQuery);
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page == state.query.page) {
      return;
    }
    await fetch(query: state.query.copyWith(page: page));
  }

  Future<void> setPageSize(int pageSize) async {
    final normalized = pageSize.clamp(5, 200);
    if (normalized == state.query.pageSize) {
      return;
    }
    await fetch(
      query: state.query.copyWith(
        page: 1,
        pageSize: normalized,
      ),
    );
  }

  Future<void> refresh() async {
    await fetch(query: state.query, force: true);
  }

  Future<void> clearFilters() async {
    await fetch(query: const InvoiceQuery());
  }

  Future<void> fetch({
    InvoiceQuery? query,
    bool force = false,
  }) async {
    final nextQuery = query ?? state.query;
    final requestId = ++_requestId;
    _persistQuery(nextQuery);

    final cacheKey = InvoiceCachePolicy.queryKey(nextQuery);

    if (!force) {
      final cached =
          InvoiceCachePolicy.get<PaginationResponse<InvoiceSummary>>(cacheKey);
      if (cached != null) {
        state = state.copyWith(
          items: cached.items,
          query: nextQuery.copyWith(
            page: cached.page,
            pageSize: cached.pageSize,
          ),
          hasMore: cached.hasMore,
          summary: cached.summary ?? const PaginationSummary(),
          viewState: cached.items.isEmpty
              ? InvoiceViewState.empty
              : InvoiceViewState.loaded,
          isInitialized: true,
          showingCachedData: true,
          clearError: true,
        );
        return;
      }
    }

    state = state.copyWith(
      query: nextQuery,
      viewState: state.isInitialized
          ? InvoiceViewState.updating
          : InvoiceViewState.loading,
      showingCachedData: false,
      clearError: true,
    );

    try {
      final response =
          await ref.read(invoiceRepositoryProvider).listInvoices(nextQuery);
      if (requestId != _requestId) {
        return;
      }

      InvoiceCachePolicy.put(cacheKey, response);
      final newState = response.items.isEmpty
          ? InvoiceViewState.empty
          : InvoiceViewState.loaded;

      state = state.copyWith(
        items: response.items,
        query: nextQuery.copyWith(
          page: response.page,
          pageSize: response.pageSize,
        ),
        hasMore: response.hasMore,
        summary: response.summary ?? const PaginationSummary(),
        viewState: newState,
        isInitialized: true,
        showingCachedData: false,
        lastSyncedAt: DateTime.now(),
        clearError: true,
      );
    } on ApiFailure catch (e) {
      if (requestId != _requestId) {
        return;
      }
      state = state.copyWith(
        viewState: state.items.isEmpty
            ? InvoiceViewState.error
            : InvoiceViewState.loaded,
        isInitialized: true,
        showingCachedData: false,
        errorMessage: e.message,
      );
    } catch (e) {
      if (requestId != _requestId) {
        return;
      }
      state = state.copyWith(
        viewState: state.items.isEmpty
            ? InvoiceViewState.error
            : InvoiceViewState.loaded,
        isInitialized: true,
        errorMessage: e.toString(),
      );
    }
  }

  void markCancelled(String invoiceId) {
    final updated = state.items.map((invoice) {
      if (invoice.id != invoiceId) {
        return invoice;
      }
      return invoice.copyWith(
        estado: 'ANULADA',
        cancelledAt: DateTime.now(),
      );
    }).toList(growable: false);

    state = state.copyWith(
      items: updated,
      viewState: updated.isEmpty ? InvoiceViewState.empty : InvoiceViewState.loaded,
    );
  }

  void _setQuery(InvoiceQuery query, {bool debounce = false}) {
    _persistQuery(query);
    state = state.copyWith(query: query, clearError: true);

    if (!debounce) {
      unawaited(fetch(query: query));
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(fetch(query: query));
    });
  }

  void _persistQuery(InvoiceQuery query) {
    ref.read(uiCacheProvider.notifier).set<InvoiceQuery>(_uiCacheKey, query);
  }
}

final invoiceListProvider =
    NotifierProvider.autoDispose<InvoiceListController, InvoiceListState>(
  InvoiceListController.new,
);
