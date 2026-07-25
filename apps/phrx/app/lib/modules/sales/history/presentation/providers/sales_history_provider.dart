import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../invoices/domain/entities/invoice_summary.dart';
import '../../data/repositories/sales_history_repository_impl.dart';
import '../../domain/entities/sales_history.dart';

enum SalesHistoryViewState { loading, loaded, empty, error, updating }

class SalesHistoryState {
  const SalesHistoryState({
    this.items = const <InvoiceSummary>[],
    this.query = const SalesHistoryQuery(),
    this.dashboard = const SalesHistoryDashboard(),
    this.summary = const PaginationSummary(),
    this.viewState = SalesHistoryViewState.loading,
    this.errorMessage,
    this.hasMore = false,
    this.isInitialized = false,
  });

  final List<InvoiceSummary> items;
  final SalesHistoryQuery query;
  final SalesHistoryDashboard dashboard;
  final PaginationSummary summary;
  final SalesHistoryViewState viewState;
  final String? errorMessage;
  final bool hasMore;
  final bool isInitialized;

  bool get isBusy =>
      viewState == SalesHistoryViewState.loading ||
      viewState == SalesHistoryViewState.updating;

  SalesHistoryState copyWith({
    List<InvoiceSummary>? items,
    SalesHistoryQuery? query,
    SalesHistoryDashboard? dashboard,
    PaginationSummary? summary,
    SalesHistoryViewState? viewState,
    String? errorMessage,
    bool? hasMore,
    bool? isInitialized,
    bool clearError = false,
  }) {
    return SalesHistoryState(
      items: items ?? this.items,
      query: query ?? this.query,
      dashboard: dashboard ?? this.dashboard,
      summary: summary ?? this.summary,
      viewState: viewState ?? this.viewState,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasMore: hasMore ?? this.hasMore,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class SalesHistoryController extends Notifier<SalesHistoryState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  SalesHistoryState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(fetch);
    return const SalesHistoryState();
  }

  void onSearchChanged(String value) {
    final next = state.query.copyWith(search: value.trim(), page: 1);
    _debounce?.cancel();
    state = state.copyWith(query: next, clearError: true);
    _debounce = Timer(const Duration(milliseconds: 350), () => fetch(query: next));
  }

  Future<void> setQuickFilter(SalesHistoryQuickFilter filter) async {
    final now = DateTime.now();
    DateTime? dateFrom;
    DateTime? dateTo;

    switch (filter) {
      case SalesHistoryQuickFilter.today:
        dateFrom = DateTime(now.year, now.month, now.day);
        dateTo = dateFrom;
      case SalesHistoryQuickFilter.week:
        final weekday = now.weekday;
        dateFrom = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: weekday - 1));
        dateTo = DateTime(now.year, now.month, now.day);
      case SalesHistoryQuickFilter.month:
        dateFrom = DateTime(now.year, now.month, 1);
        dateTo = DateTime(now.year, now.month + 1, 0);
      case SalesHistoryQuickFilter.none:
        break;
    }

    await fetch(
      query: state.query.copyWith(
        page: 1,
        quickFilter: filter,
        dateFrom: dateFrom,
        dateTo: dateTo,
        clearDateRange: filter == SalesHistoryQuickFilter.none,
      ),
    );
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page == state.query.page) return;
    await fetch(query: state.query.copyWith(page: page));
  }

  Future<void> setPageSize(int pageSize) async {
    final normalized = pageSize.clamp(5, 100);
    if (normalized == state.query.pageSize) return;
    await fetch(query: state.query.copyWith(page: 1, pageSize: normalized));
  }

  Future<void> refresh() => fetch(force: true);

  Future<void> clearFilters() => fetch(query: const SalesHistoryQuery());

  Future<void> fetch({SalesHistoryQuery? query, bool force = false}) async {
    final nextQuery = query ?? state.query;
    final requestId = ++_requestId;

    state = state.copyWith(
      query: nextQuery,
      viewState: state.isInitialized
          ? SalesHistoryViewState.updating
          : SalesHistoryViewState.loading,
      clearError: true,
    );

    try {
      final repo = ref.read(salesHistoryRepositoryProvider);
      final response = await repo.listSales(nextQuery);
      final dashboard = await repo.getDashboard(
        dateFrom: nextQuery.dateFrom,
        dateTo: nextQuery.dateTo,
      );

      if (requestId != _requestId) return;

      state = state.copyWith(
        items: response.items,
        query: nextQuery.copyWith(page: response.page, pageSize: response.pageSize),
        dashboard: dashboard,
        summary: response.summary ?? const PaginationSummary(),
        hasMore: response.hasMore,
        viewState: response.items.isEmpty
            ? SalesHistoryViewState.empty
            : SalesHistoryViewState.loaded,
        isInitialized: true,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(
        viewState: state.items.isEmpty
            ? SalesHistoryViewState.error
            : SalesHistoryViewState.loaded,
        isInitialized: true,
        errorMessage: e.message,
      );
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(
        viewState: state.items.isEmpty
            ? SalesHistoryViewState.error
            : SalesHistoryViewState.loaded,
        isInitialized: true,
        errorMessage: e.toString(),
      );
    }
  }
}

final salesHistoryProvider =
    NotifierProvider.autoDispose<SalesHistoryController, SalesHistoryState>(
  SalesHistoryController.new,
);
