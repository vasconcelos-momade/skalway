import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/contracts/pagination_response.dart';
import '../../../../core/errors/api_failure.dart';
import '../../data/datasources/purchase_suggestions_remote_datasource.dart';
import '../../data/models/purchase_suggestion_models.dart';

export '../../data/models/purchase_suggestion_models.dart';

DateTime purchaseSuggestionsDefaultDataInicial() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return today.subtract(const Duration(days: 30));
}

DateTime purchaseSuggestionsDefaultDataFinal() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

String formatPurchaseSuggestionApiDate(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '${normalized.year}-$month-$day';
}

class PurchaseSuggestionsState {
  PurchaseSuggestionsState({
    this.items = const <PurchaseSuggestionItem>[],
    this.groupedByFornecedor = const <PurchaseSuggestionGroup>[],
    this.dashboard = const PurchaseSuggestionDashboard(),
    this.search = '',
    this.originFilter = PurchaseSuggestionOriginFilter.todas,
    DateTime? dataInicial,
    DateTime? dataFinal,
    this.page = 1,
    this.pageSize = PaginationDefaults.pageSize,
    this.totalCount,
    this.hasMore = false,
    this.isLoading = false,
    this.isMutating = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.successMessage,
  })  : dataInicial = dataInicial ?? purchaseSuggestionsDefaultDataInicial(),
        dataFinal = dataFinal ?? purchaseSuggestionsDefaultDataFinal();

  final List<PurchaseSuggestionItem> items;
  final List<PurchaseSuggestionGroup> groupedByFornecedor;
  final PurchaseSuggestionDashboard dashboard;
  final String search;
  final PurchaseSuggestionOriginFilter originFilter;
  final DateTime dataInicial;
  final DateTime dataFinal;
  final int page;
  final int pageSize;
  final int? totalCount;
  final bool hasMore;
  final bool isLoading;
  final bool isMutating;
  final bool isRefreshing;
  final String? errorMessage;
  final String? successMessage;

  PurchaseSuggestionsState copyWith({
    List<PurchaseSuggestionItem>? items,
    List<PurchaseSuggestionGroup>? groupedByFornecedor,
    PurchaseSuggestionDashboard? dashboard,
    String? search,
    PurchaseSuggestionOriginFilter? originFilter,
    DateTime? dataInicial,
    DateTime? dataFinal,
    int? page,
    int? pageSize,
    int? totalCount,
    bool? hasMore,
    bool? isLoading,
    bool? isMutating,
    bool? isRefreshing,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return PurchaseSuggestionsState(
      items: items ?? this.items,
      groupedByFornecedor: groupedByFornecedor ?? this.groupedByFornecedor,
      dashboard: dashboard ?? this.dashboard,
      search: search ?? this.search,
      originFilter: originFilter ?? this.originFilter,
      dataInicial: dataInicial ?? this.dataInicial,
      dataFinal: dataFinal ?? this.dataFinal,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

class PurchaseSuggestionsController extends Notifier<PurchaseSuggestionsState> {
  @override
  PurchaseSuggestionsState build() {
    Future.microtask(load);
    return PurchaseSuggestionsState(isLoading: true);
  }

  PurchaseSuggestionsRemoteDataSource get _dataSource =>
      ref.read(purchaseSuggestionsRemoteDataSourceProvider);

  Future<void> setSearch(String value) async {
    state = state.copyWith(search: value, page: 1, isLoading: true, clearMessages: true);
    await load();
  }

  Future<void> setDataInicial(DateTime value) async {
    final normalized = DateTime(value.year, value.month, value.day);
    state = state.copyWith(dataInicial: normalized, clearMessages: true);
  }

  Future<void> setDataFinal(DateTime value) async {
    final normalized = DateTime(value.year, value.month, value.day);
    state = state.copyWith(dataFinal: normalized, clearMessages: true);
  }

  Future<void> setOriginFilter(PurchaseSuggestionOriginFilter filter) async {
    state = state.copyWith(
      originFilter: filter,
      page: 1,
      isLoading: true,
      clearMessages: true,
    );
    await load();
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page == state.page) return;
    state = state.copyWith(page: page, isLoading: true, clearMessages: true);
    await load();
  }

  Future<void> setPageSize(int pageSize) async {
    if (pageSize == state.pageSize) return;
    state = state.copyWith(
      pageSize: pageSize,
      page: 1,
      isLoading: true,
      clearMessages: true,
    );
    await load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final response = await _dataSource.fetchSuggestions(
        query: state.search,
        originFilter: state.originFilter,
        dataInicio: formatPurchaseSuggestionApiDate(state.dataInicial),
        dataFim: formatPurchaseSuggestionApiDate(state.dataFinal),
        page: state.page,
        pageSize: state.pageSize,
      );

      state = state.copyWith(
        items: response.items,
        groupedByFornecedor: response.groupedByFornecedor,
        dashboard: response.dashboard,
        totalCount: response.totalCount,
        hasMore: response.hasMore,
        page: response.page,
        pageSize: response.pageSize,
        isLoading: false,
        clearMessages: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> addManualSuggestion({
    required String produtoId,
    required String supplierId,
    int? quantidadeAprovada,
  }) async {
    state = state.copyWith(isMutating: true, clearMessages: true);
    try {
      final message = await _dataSource.addManualSuggestion(
        produtoId: produtoId,
        supplierId: supplierId,
        quantidadeAprovada: quantidadeAprovada,
      );
      state = state.copyWith(isMutating: false, successMessage: message);
      await load();
    } on ApiFailure catch (e) {
      state = state.copyWith(isMutating: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isMutating: false, errorMessage: e.toString());
    }
  }

  Future<void> updateSuggestion({
    required String produtoId,
    required String supplierId,
    int? quantidadeAprovada,
  }) async {
    state = state.copyWith(isMutating: true, clearMessages: true);
    try {
      final message = await _dataSource.updateSuggestion(
        produtoId: produtoId,
        supplierId: supplierId,
        quantidadeAprovada: quantidadeAprovada,
      );
      state = state.copyWith(isMutating: false, successMessage: message);
      await load();
    } on ApiFailure catch (e) {
      state = state.copyWith(isMutating: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isMutating: false, errorMessage: e.toString());
    }
  }

  Future<void> refreshList() async {
    if (state.isRefreshing) return;

    final inicio = DateTime(
      state.dataInicial.year,
      state.dataInicial.month,
      state.dataInicial.day,
    );
    final fim = DateTime(
      state.dataFinal.year,
      state.dataFinal.month,
      state.dataFinal.day,
    );
    if (inicio.isAfter(fim)) {
      state = state.copyWith(
        errorMessage: 'Data inicial não pode ser posterior à data final',
        clearMessages: true,
      );
      return;
    }

    state = state.copyWith(isRefreshing: true, clearMessages: true);
    try {
      final message = await _dataSource.refreshSuggestions(
        dataInicio: formatPurchaseSuggestionApiDate(inicio),
        dataFim: formatPurchaseSuggestionApiDate(fim),
      );
      state = state.copyWith(isRefreshing: false, successMessage: message);
      await load();
    } on ApiFailure catch (e) {
      state = state.copyWith(isRefreshing: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isRefreshing: false, errorMessage: e.toString());
    }
  }

  Future<void> updateApprovedQuantity({
    required String produtoId,
    required int quantidadeAprovada,
  }) async {
    state = state.copyWith(isMutating: true, clearMessages: true);
    try {
      final message = await _dataSource.updateApprovedQuantity(
        produtoId: produtoId,
        quantidadeAprovada: quantidadeAprovada,
      );
      state = state.copyWith(isMutating: false, successMessage: message);
      await load();
    } on ApiFailure catch (e) {
      state = state.copyWith(isMutating: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isMutating: false, errorMessage: e.toString());
    }
  }

  Future<void> removeSuggestion(String produtoId) async {
    state = state.copyWith(isMutating: true, clearMessages: true);
    try {
      await _dataSource.removeSuggestion(produtoId);
      state = state.copyWith(
        isMutating: false,
        successMessage: 'Sugestão removida',
      );
      await load();
    } on ApiFailure catch (e) {
      state = state.copyWith(isMutating: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isMutating: false, errorMessage: e.toString());
    }
  }

  Future<void> clearSuggestions() async {
    state = state.copyWith(isMutating: true, clearMessages: true);
    try {
      final message = await _dataSource.clearSuggestions();
      state = state.copyWith(isMutating: false, successMessage: message);
      await load();
    } on ApiFailure catch (e) {
      state = state.copyWith(isMutating: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isMutating: false, errorMessage: e.toString());
    }
  }
}

final purchaseSuggestionsProvider =
    NotifierProvider.autoDispose<PurchaseSuggestionsController, PurchaseSuggestionsState>(
  PurchaseSuggestionsController.new,
);
