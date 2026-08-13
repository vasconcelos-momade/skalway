import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/api_failure.dart';
import '../../data/datasources/pharmacy_service_remote_datasource.dart';
import '../../domain/entities/pharmacy_service.dart';

class PharmacyServiceListState {
  const PharmacyServiceListState({
    this.items = const <PharmacyService>[],
    this.query = '',
    this.includeInactive = true,
    this.page = 1,
    this.pageSize = 10,
    this.hasMore = false,
    this.totalCount,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<PharmacyService> items;
  final String query;
  final bool includeInactive;
  final int page;
  final int pageSize;
  final bool hasMore;
  final int? totalCount;
  final bool isLoading;
  final String? errorMessage;

  PharmacyServiceListState copyWith({
    List<PharmacyService>? items,
    String? query,
    bool? includeInactive,
    int? page,
    int? pageSize,
    bool? hasMore,
    int? totalCount,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PharmacyServiceListState(
      items: items ?? this.items,
      query: query ?? this.query,
      includeInactive: includeInactive ?? this.includeInactive,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PharmacyServiceListController extends Notifier<PharmacyServiceListState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  PharmacyServiceListState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(load);
    return const PharmacyServiceListState();
  }

  void onSearchChanged(String value) {
    _debounce?.cancel();
    state = state.copyWith(
      query: value.trim(),
      page: 1,
      isLoading: true,
      clearError: true,
    );
    _debounce = Timer(const Duration(milliseconds: 350), load);
  }

  void setIncludeInactive(bool value) {
    state = state.copyWith(
      includeInactive: value,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    unawaited(load());
  }

  void setPageSize(int size) {
    if (size == state.pageSize) return;
    state = state.copyWith(
      pageSize: size,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    unawaited(load());
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page == state.page) return;
    state = state.copyWith(page: page, isLoading: true, clearError: true);
    await load();
  }

  Future<void> load() async {
    final requestId = ++_requestId;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response =
          await ref.read(pharmacyServiceRemoteDataSourceProvider).search(
                query: state.query.isEmpty ? null : state.query,
                includeInactive: state.includeInactive,
                page: state.page,
                pageSize: state.pageSize,
              );
      if (requestId != _requestId) return;
      state = state.copyWith(
        items: response.items.map((m) => m.toEntity()).toList(),
        page: response.page,
        pageSize: response.pageSize,
        hasMore: response.hasMore,
        totalCount: response.totalCount,
        isLoading: false,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      if (requestId != _requestId) return;
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> create(Map<String, dynamic> payload) async {
    await ref.read(pharmacyServiceRemoteDataSourceProvider).create(payload);
    await load();
  }

  Future<void> update(String id, Map<String, dynamic> payload) async {
    await ref.read(pharmacyServiceRemoteDataSourceProvider).update(id, payload);
    await load();
  }

  Future<void> delete(String id) async {
    await ref.read(pharmacyServiceRemoteDataSourceProvider).delete(id);
    await load();
  }
}

final pharmacyServiceListProvider =
    NotifierProvider<PharmacyServiceListController, PharmacyServiceListState>(
  PharmacyServiceListController.new,
);

final pharmacyServiceStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(pharmacyServiceRemoteDataSourceProvider).stats();
});
