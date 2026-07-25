import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/api_failure.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../domain/entities/customer.dart';

enum CustomerViewState { loading, loaded, empty, error, updating }

class CustomerListState {
  const CustomerListState({
    this.items = const <CustomerSummary>[],
    this.query = const CustomerQuery(),
    this.dashboard = const CustomerDashboard(),
    this.viewState = CustomerViewState.loading,
    this.errorMessage,
    this.hasMore = false,
    this.isInitialized = false,
  });

  final List<CustomerSummary> items;
  final CustomerQuery query;
  final CustomerDashboard dashboard;
  final CustomerViewState viewState;
  final String? errorMessage;
  final bool hasMore;
  final bool isInitialized;

  bool get isBusy =>
      viewState == CustomerViewState.loading ||
      viewState == CustomerViewState.updating;

  CustomerListState copyWith({
    List<CustomerSummary>? items,
    CustomerQuery? query,
    CustomerDashboard? dashboard,
    CustomerViewState? viewState,
    String? errorMessage,
    bool? hasMore,
    bool? isInitialized,
    bool clearError = false,
  }) {
    return CustomerListState(
      items: items ?? this.items,
      query: query ?? this.query,
      dashboard: dashboard ?? this.dashboard,
      viewState: viewState ?? this.viewState,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasMore: hasMore ?? this.hasMore,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class CustomerListController extends Notifier<CustomerListState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  CustomerListState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(fetch);
    return const CustomerListState();
  }

  void onSearchChanged(String value) {
    final next = state.query.copyWith(search: value.trim(), page: 1);
    _debounce?.cancel();
    state = state.copyWith(query: next, clearError: true);
    _debounce = Timer(const Duration(milliseconds: 350), () => fetch(query: next));
  }

  Future<void> setTipoFilter(String? tipo) async {
    await fetch(
      query: state.query.copyWith(page: 1, tipo: tipo, clearTipo: tipo == null),
    );
  }

  Future<void> setComCreditoFilter(bool? value) async {
    await fetch(
      query: state.query.copyWith(
        page: 1,
        comCredito: value,
        clearComCredito: value == null,
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

  Future<void> clearFilters() => fetch(query: const CustomerQuery());

  Future<CustomerDetail> createCustomer(CustomerFormPayload payload) async {
    final repo = ref.read(customerRepositoryProvider);
    final created = await repo.createCustomer(payload);
    await fetch(force: true);
    return created;
  }

  Future<CustomerDetail> updateCustomer(
    String id,
    CustomerFormPayload payload,
  ) async {
    final repo = ref.read(customerRepositoryProvider);
    final updated = await repo.updateCustomer(id, payload);
    await fetch(force: true);
    return updated;
  }

  Future<void> deleteCustomer(String id) async {
    final repo = ref.read(customerRepositoryProvider);
    await repo.deleteCustomer(id);
    await fetch(force: true);
  }

  Future<void> fetch({CustomerQuery? query, bool force = false}) async {
    final nextQuery = query ?? state.query;
    final requestId = ++_requestId;

    state = state.copyWith(
      query: nextQuery,
      viewState: state.isInitialized
          ? CustomerViewState.updating
          : CustomerViewState.loading,
      clearError: true,
    );

    try {
      final repo = ref.read(customerRepositoryProvider);
      final response = await repo.listCustomers(nextQuery);
      CustomerDashboard dashboard = state.dashboard;
      if (!state.isInitialized || force) {
        dashboard = await repo.getDashboard();
      }

      if (requestId != _requestId) return;

      state = state.copyWith(
        items: response.items,
        query: nextQuery.copyWith(
          page: response.page,
          pageSize: response.pageSize,
        ),
        dashboard: dashboard,
        hasMore: response.hasMore,
        viewState: response.items.isEmpty
            ? CustomerViewState.empty
            : CustomerViewState.loaded,
        isInitialized: true,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(
        viewState: state.items.isEmpty
            ? CustomerViewState.error
            : CustomerViewState.loaded,
        isInitialized: true,
        errorMessage: e.message,
      );
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(
        viewState: state.items.isEmpty
            ? CustomerViewState.error
            : CustomerViewState.loaded,
        isInitialized: true,
        errorMessage: e.toString(),
      );
    }
  }
}

final customerListProvider =
    NotifierProvider.autoDispose<CustomerListController, CustomerListState>(
  CustomerListController.new,
);
