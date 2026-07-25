import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/contracts/pagination_response.dart';
import '../../../../core/errors/api_failure.dart';
import '../../data/datasources/terminal_remote_datasource.dart';
import '../../domain/entities/terminal.dart';

class TerminalListState {
  const TerminalListState({
    this.items = const <TerminalDetalhe>[],
    this.query = '',
    this.page = 1,
    this.pageSize = PaginationDefaults.pageSize,
    this.hasMore = false,
    this.totalCount,
    this.isLoading = false,
    this.isInitialized = false,
    this.errorMessage,
  });

  final List<TerminalDetalhe> items;
  final String query;
  final int page;
  final int pageSize;
  final bool hasMore;
  final int? totalCount;
  final bool isLoading;
  final bool isInitialized;
  final String? errorMessage;

  TerminalListState copyWith({
    List<TerminalDetalhe>? items,
    String? query,
    int? page,
    int? pageSize,
    bool? hasMore,
    int? totalCount,
    bool? isLoading,
    bool? isInitialized,
    String? errorMessage,
    bool clearError = false,
    bool clearTotalCount = false,
  }) {
    return TerminalListState(
      items: items ?? this.items,
      query: query ?? this.query,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      totalCount: clearTotalCount ? null : (totalCount ?? this.totalCount),
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TerminalListController extends Notifier<TerminalListState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  TerminalListState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(fetchCurrentPage);
    return const TerminalListState(isLoading: true);
  }

  void onSearchChanged(String value) {
    final normalized = value.trim();
    if (normalized == state.query) return;
    _debounce?.cancel();
    state = state.copyWith(query: normalized, page: 1, isLoading: true, clearError: true);
    _debounce = Timer(const Duration(milliseconds: 350), fetchCurrentPage);
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page == state.page) return;
    state = state.copyWith(page: page, isLoading: true, clearError: true);
    await fetchCurrentPage();
  }

  Future<void> setPageSize(int pageSize) async {
    final normalized = pageSize.clamp(5, 100);
    if (normalized == state.pageSize) return;
    state = state.copyWith(
      page: 1,
      pageSize: normalized,
      isLoading: true,
      clearError: true,
      clearTotalCount: true,
    );
    await fetchCurrentPage();
  }

  Future<void> refreshCurrentPage() => fetchCurrentPage(force: true);

  Future<void> fetchCurrentPage({bool force = false}) async {
    final requestId = ++_requestId;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await ref.read(terminalRemoteDataSourceProvider).search(
            query: state.query,
            page: state.page,
            pageSize: state.pageSize,
            includeInactive: true,
          );

      if (requestId != _requestId) return;

      state = state.copyWith(
        items: response.items.map((item) => item.toEntity()).toList(),
        page: response.page,
        pageSize: response.pageSize,
        hasMore: response.hasMore,
        totalCount: response.totalCount,
        isLoading: false,
        isInitialized: true,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: e.message,
      );
    } catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> create(Map<String, dynamic> payload) async {
    await ref.read(terminalRemoteDataSourceProvider).create(payload);
    await fetchCurrentPage(force: true);
  }

  Future<void> update(String id, Map<String, dynamic> payload) async {
    await ref.read(terminalRemoteDataSourceProvider).update(id, payload);
    await fetchCurrentPage(force: true);
  }

  Future<void> delete(String id) async {
    await ref.read(terminalRemoteDataSourceProvider).delete(id);
    await fetchCurrentPage(force: true);
  }
}

final terminalListProvider =
    NotifierProvider.autoDispose<TerminalListController, TerminalListState>(
  TerminalListController.new,
);
