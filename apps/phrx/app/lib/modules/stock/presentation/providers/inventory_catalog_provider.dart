import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/catalog/inventory_catalog_cache_policy.dart';
import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../data/repositories/inventario_repository_impl.dart';
import '../../domain/entities/inventario.dart';

class InventoryCatalogState {
  const InventoryCatalogState({
    this.items = const <InventarioProdutoApto>[],
    this.query = '',
    this.categoriaId,
    this.estadoSanitario = 'VALIDO',
    this.page = 1,
    this.pageSize = 20,
    this.hasMore = false,
    this.totalCount,
    this.stockTotalPage = 0,
    this.isLoading = false,
    this.isInitialized = false,
    this.errorMessage,
  });

  final List<InventarioProdutoApto> items;
  final String query;
  final String? categoriaId;
  final String estadoSanitario;
  final int page;
  final int pageSize;
  final bool hasMore;
  final int? totalCount;
  final double stockTotalPage;
  final bool isLoading;
  final bool isInitialized;
  final String? errorMessage;

  bool get hasFilters =>
      query.isNotEmpty ||
      (categoriaId != null && categoriaId!.isNotEmpty) ||
      estadoSanitario != 'VALIDO';

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
    List<InventarioProdutoApto>? items,
    String? query,
    String? categoriaId,
    bool clearCategoriaId = false,
    String? estadoSanitario,
    int? page,
    int? pageSize,
    bool? hasMore,
    int? totalCount,
    double? stockTotalPage,
    bool? isLoading,
    bool? isInitialized,
    String? errorMessage,
    bool clearError = false,
    bool clearTotalCount = false,
  }) {
    return InventoryCatalogState(
      items: items ?? this.items,
      query: query ?? this.query,
      categoriaId:
          clearCategoriaId ? null : (categoriaId ?? this.categoriaId),
      estadoSanitario: estadoSanitario ?? this.estadoSanitario,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      totalCount: clearTotalCount ? null : (totalCount ?? this.totalCount),
      stockTotalPage: stockTotalPage ?? this.stockTotalPage,
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
    Future.microtask(fetchCurrentPage);
    return const InventoryCatalogState(isLoading: true);
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

  Future<void> setCategoriaFilter(String? categoriaId) async {
    state = state.copyWith(
      clearCategoriaId: categoriaId == null || categoriaId.isEmpty,
      categoriaId: categoriaId,
      page: 1,
      isLoading: true,
      clearError: true,
      clearTotalCount: true,
    );
    await fetchCurrentPage();
  }

  Future<void> setEstadoSanitarioFilter(String? value) async {
    state = state.copyWith(
      estadoSanitario: value == null || value.isEmpty ? 'VALIDO' : value,
      page: 1,
      isLoading: true,
      clearError: true,
      clearTotalCount: true,
    );
    await fetchCurrentPage();
  }

  Future<void> clearFilters() async {
    state = state.copyWith(
      query: '',
      clearCategoriaId: true,
      estadoSanitario: 'VALIDO',
      page: 1,
      isLoading: true,
      clearError: true,
      clearTotalCount: true,
    );
    await fetchCurrentPage();
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
    final requestId = ++_requestId;
    final cacheKey = InventoryCatalogCachePolicy.itemPageKey(
      inventoryId: 'produtos-aptos',
      query:
          '${state.query}|${state.categoriaId ?? ''}|${state.estadoSanitario}',
      page: state.page,
      pageSize: state.pageSize,
    );

    if (!force) {
      final cached =
          InventoryCatalogCachePolicy.get<PaginationResponse<InventarioProdutoApto>>(
        cacheKey,
      );
      if (cached != null) {
        state = state.copyWith(
          items: cached.items,
          page: cached.page,
          pageSize: cached.pageSize,
          hasMore: cached.hasMore,
          totalCount: cached.totalCount,
          stockTotalPage: cached.items.fold<double>(
            0,
            (sum, item) => sum + item.stockAtual,
          ),
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
          .listarProdutosAptos(
            query: state.query,
            categoriaId: state.categoriaId,
            estadoSanitario: state.estadoSanitario,
            page: state.page,
            pageSize: state.pageSize,
          );

      if (requestId != _requestId) return;

      InventoryCatalogCachePolicy.put(cacheKey, response);

      state = state.copyWith(
        items: response.items,
        page: response.page,
        pageSize: response.pageSize,
        hasMore: response.hasMore,
        totalCount: response.totalCount,
        stockTotalPage: response.items.fold<double>(
          0,
          (sum, item) => sum + item.stockAtual,
        ),
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
}

final inventoryCatalogProvider =
    NotifierProvider.autoDispose<InventoryCatalogController, InventoryCatalogState>(
      InventoryCatalogController.new,
    );
