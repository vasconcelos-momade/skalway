import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/catalog/inventory_catalog_cache_policy.dart';
import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../data/repositories/inventario_repository_impl.dart';
import '../../domain/entities/inventario.dart';
import 'inventario_provider.dart';

class InventoryCatalogState {
  const InventoryCatalogState({
    this.inventoryId,
    this.items = const <InventarioItem>[],
    this.query = '',
    this.page = 1,
    this.pageSize = 20,
    this.hasMore = false,
    this.totalCount,
    this.isLoading = false,
    this.isInitialized = false,
    this.errorMessage,
  });

  final String? inventoryId;
  final List<InventarioItem> items;
  final String query;
  final int page;
  final int pageSize;
  final bool hasMore;
  final int? totalCount;
  final bool isLoading;
  final bool isInitialized;
  final String? errorMessage;

  int? get resolvedTotalCount {
    if (totalCount != null) return totalCount;
    if (!hasMore && items.isNotEmpty) {
      return ((page - 1) * pageSize) + items.length;
    }
    if (hasMore) {
      return (page * pageSize) + 1;
    }
    return items.isEmpty ? 0 : null;
  }

  InventoryCatalogState copyWith({
    String? inventoryId,
    List<InventarioItem>? items,
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
    return InventoryCatalogState(
      inventoryId: inventoryId ?? this.inventoryId,
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

class InventoryCatalogController extends Notifier<InventoryCatalogState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  InventoryCatalogState build() {
    ref.onDispose(() {
      _debounce?.cancel();
    });

    final inventoryId = ref.watch(
      inventarioProvider.select((state) => state.activeInventory?.id),
    );
    final nextState = InventoryCatalogState(inventoryId: inventoryId);
    if (inventoryId != null) {
      Future.microtask(fetchCurrentPage);
    }
    return nextState;
  }

  void onSearchChanged(String value) {
    final normalized = value.trim();
    if (normalized == state.query) {
      return;
    }

    _debounce?.cancel();
    state = state.copyWith(
      query: normalized,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    _debounce = Timer(const Duration(milliseconds: 350), fetchCurrentPage);
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page == state.page) {
      return;
    }
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

  Future<void> refreshCurrentPage() async {
    await fetchCurrentPage(force: true);
  }

  Future<void> fetchCurrentPage({bool force = false}) async {
    final inventoryId = state.inventoryId;
    if (inventoryId == null || inventoryId.isEmpty) {
      state = const InventoryCatalogState(isInitialized: true);
      return;
    }

    final requestId = ++_requestId;
    final cacheKey = InventoryCatalogCachePolicy.itemPageKey(
      inventoryId: inventoryId,
      query: state.query,
      page: state.page,
      pageSize: state.pageSize,
    );

    if (!force) {
      final cached =
          InventoryCatalogCachePolicy.get<PaginationResponse<InventarioItem>>(
            cacheKey,
          );
      if (cached != null) {
        state = state.copyWith(
          items: cached.items,
          page: cached.page,
          pageSize: cached.pageSize,
          hasMore: cached.hasMore,
          totalCount: cached.totalCount,
          isLoading: false,
          isInitialized: true,
          clearError: true,
        );
        return;
      }
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await ref
          .read(inventarioRepositoryProvider)
          .listarItensInventario(
            inventarioId: inventoryId,
            query: state.query,
            page: state.page,
            pageSize: state.pageSize,
          );

      if (requestId != _requestId) {
        return;
      }

      InventoryCatalogCachePolicy.put(cacheKey, response);
      state = state.copyWith(
        items: response.items,
        page: response.page,
        pageSize: response.pageSize,
        hasMore: response.hasMore,
        totalCount: response.totalCount,
        isLoading: false,
        isInitialized: true,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      if (requestId != _requestId) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: e.message,
      );
    } catch (e) {
      if (requestId != _requestId) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: e.toString(),
      );
    }
  }
}

final inventoryCatalogProvider =
    NotifierProvider.autoDispose<
      InventoryCatalogController,
      InventoryCatalogState
    >(InventoryCatalogController.new);
