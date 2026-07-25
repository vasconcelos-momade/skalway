import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers/auth_session_notifier.dart';
import '../../../../../core/catalog/pdv_catalog_cache_policy.dart';
import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_tax_rule.dart';

class ProductListState {
  const ProductListState({
    this.items = const <Product>[],
    this.query = '',
    this.categoriaId,
    this.page = 1,
    this.pageSize = PaginationDefaults.pageSize,
    this.hasMore = false,
    this.totalCount,
    this.isLoading = false,
    this.isInitialized = false,
    this.errorMessage,
    this.catalogVersion,
  });

  final List<Product> items;
  final String query;
  final String? categoriaId;
  final int page;
  final int pageSize;
  final bool hasMore;
  final int? totalCount;
  final bool isLoading;
  final bool isInitialized;
  final String? errorMessage;
  final String? catalogVersion;

  ProductListState copyWith({
    List<Product>? items,
    String? query,
    String? categoriaId,
    bool clearCategoria = false,
    int? page,
    int? pageSize,
    bool? hasMore,
    int? totalCount,
    bool? isLoading,
    bool? isInitialized,
    String? errorMessage,
    String? catalogVersion,
    bool clearError = false,
  }) {
    return ProductListState(
      items: items ?? this.items,
      query: query ?? this.query,
      categoriaId: clearCategoria ? null : (categoriaId ?? this.categoriaId),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      catalogVersion: catalogVersion ?? this.catalogVersion,
    );
  }
}

class ProductListController extends Notifier<ProductListState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  ProductListState build() {
    ref.onDispose(() {
      _debounce?.cancel();
    });

    final authReady = ref.watch(
      authSessionProvider.select(
        (session) => !session.isBootstrapping && session.hasTenantContext,
      ),
    );

    ref.listen<AuthSessionState>(authSessionProvider, (previous, next) {
      final previousSession = previous?.session;
      final nextSession = next.session;
      final wasReady =
          previous != null && !previous.isBootstrapping && previous.hasTenantContext;
      final isReady = !next.isBootstrapping && next.hasTenantContext;

      if (!isReady) {
        state = const ProductListState();
        return;
      }

      final tenantChanged =
          previousSession?.tenantId != nextSession?.tenantId ||
          previousSession?.branchId != nextSession?.branchId;

      if (isReady && (!wasReady || tenantChanged)) {
        unawaited(fetchCurrentPage(force: true));
      }
    });

    if (authReady) {
      Future.microtask(fetchCurrentPage);
    }
    return const ProductListState();
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
      clearError: true,
    );

    _debounce = Timer(const Duration(milliseconds: 350), () {
      fetchCurrentPage();
    });
  }

  void setCategoriaFilter(String? categoriaId) {
    if (state.categoriaId == categoriaId) {
      return;
    }

    _debounce?.cancel();
    state = state.copyWith(
      categoriaId: categoriaId,
      clearCategoria: categoriaId == null,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    unawaited(fetchCurrentPage());
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page == state.page) {
      return;
    }
    state = state.copyWith(page: page, isLoading: true, clearError: true);
    await fetchCurrentPage();
  }

  void setPageSize(int pageSize) {
    if (pageSize < 1 || pageSize == state.pageSize) {
      return;
    }
    state = state.copyWith(
      pageSize: pageSize,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    unawaited(fetchCurrentPage());
  }

  Future<void> refreshCurrentPage() async {
    await fetchCurrentPage(force: true);
  }

  /// Actualiza `catalogVersion` no servidor e recarrega a página actual.
  Future<void> refreshCatalogAndPage() async {
    final repository = ref.read(productRepositoryProvider);
    await repository.fetchCatalogVersion();
    await fetchCurrentPage(force: true);
  }

  Future<void> fetchCurrentPage({bool force = false}) async {
    if (!ref.read(authSessionProvider).hasTenantContext) {
      state = const ProductListState();
      return;
    }

    final requestId = ++_requestId;
    final isBarcode = _looksLikeBarcode(state.query);
    final cacheKey = PdvCatalogCachePolicy.productPageKey(
      query: state.query,
      categoria: state.categoriaId,
      page: state.page,
      pageSize: state.pageSize,
    );

    if (!force && !isBarcode) {
      final cached =
          PdvCatalogCachePolicy.get<PaginationResponse<Product>>(cacheKey);
      if (cached != null) {
        state = state.copyWith(
          items: cached.items,
          page: cached.page,
          pageSize: cached.pageSize,
          hasMore: cached.hasMore,
          totalCount: cached.totalCount,
          isLoading: false,
          isInitialized: true,
          catalogVersion: PdvCatalogCachePolicy.activeCatalogVersion,
          clearError: true,
        );
        return;
      }
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(productRepositoryProvider);
      final response = await repository.searchProducts(
        query: isBarcode ? null : state.query,
        barcode: isBarcode ? state.query : null,
        categoriaId: state.categoriaId,
        page: state.page,
        pageSize: state.pageSize,
      );

      if (requestId != _requestId) {
        return;
      }

      if (!isBarcode) {
        PdvCatalogCachePolicy.put(cacheKey, response);
      }

      state = state.copyWith(
        items: response.items,
        page: response.page,
        pageSize: response.pageSize,
        hasMore: response.hasMore,
        totalCount: response.totalCount,
        isLoading: false,
        isInitialized: true,
        catalogVersion: PdvCatalogCachePolicy.activeCatalogVersion,
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

  bool _looksLikeBarcode(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 8) {
      return false;
    }
    return RegExp(r'^\d+$').hasMatch(trimmed);
  }
}

final productListProvider =
    NotifierProvider.autoDispose<ProductListController, ProductListState>(
  ProductListController.new,
);

final productTaxRulesProvider =
    FutureProvider.autoDispose<List<ProductTaxRule>>((ref) async {
  final tenantId = ref.watch(
    authSessionProvider.select(
      (session) => !session.isBootstrapping && session.hasTenantContext
          ? session.session?.tenantId
          : null,
    ),
  );
  if (tenantId == null) {
    return const <ProductTaxRule>[];
  }

  final repository = ref.read(productRepositoryProvider);
  return repository.listTaxRules();
});

class MasterProductListState {
  const MasterProductListState({
    this.items = const <Product>[],
    this.query = '',
    this.categoriaId,
    this.fornecedorId,
    this.tipoDispensacao,
    this.ativoFilter,
    this.includeInactive = false,
    this.sortBy = 'nomeComercial',
    this.sortOrder = 'asc',
    this.deletingProductIds = const <String>{},
    this.page = 1,
    this.pageSize = PaginationDefaults.pageSize,
    this.hasMore = false,
    this.totalCount,
    this.isLoading = false,
    this.isInitialized = false,
    this.errorMessage,
  });

  final List<Product> items;
  final String query;
  final String? categoriaId;
  final String? fornecedorId;
  final String? tipoDispensacao;
  final bool? ativoFilter;
  final bool includeInactive;
  final String sortBy;
  final String sortOrder;
  final Set<String> deletingProductIds;
  final int page;
  final int pageSize;
  final bool hasMore;
  final int? totalCount;
  final bool isLoading;
  final bool isInitialized;
  final String? errorMessage;

  bool get hasFilters =>
      ativoFilter != null ||
      categoriaId != null;

  MasterProductListState copyWith({
    List<Product>? items,
    String? query,
    String? categoriaId,
    bool clearCategoriaId = false,
    String? fornecedorId,
    bool clearFornecedorId = false,
    String? tipoDispensacao,
    bool clearTipoDispensacao = false,
    bool? ativoFilter,
    bool clearAtivoFilter = false,
    bool? includeInactive,
    String? sortBy,
    String? sortOrder,
    Set<String>? deletingProductIds,
    int? page,
    int? pageSize,
    bool? hasMore,
    int? totalCount,
    bool? isLoading,
    bool? isInitialized,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MasterProductListState(
      items: items ?? this.items,
      query: query ?? this.query,
      categoriaId: clearCategoriaId ? null : (categoriaId ?? this.categoriaId),
      fornecedorId:
          clearFornecedorId ? null : (fornecedorId ?? this.fornecedorId),
      tipoDispensacao: clearTipoDispensacao
          ? null
          : (tipoDispensacao ?? this.tipoDispensacao),
      ativoFilter: clearAtivoFilter ? null : (ativoFilter ?? this.ativoFilter),
      includeInactive: includeInactive ?? this.includeInactive,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      deletingProductIds: deletingProductIds ?? this.deletingProductIds,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class MasterProductListController extends Notifier<MasterProductListState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  MasterProductListState build() {
    ref.onDispose(() {
      _debounce?.cancel();
    });
    Future.microtask(load);
    return const MasterProductListState();
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

    _debounce = Timer(const Duration(milliseconds: 350), () {
      load();
    });
  }

  void setCategoriaIdFilter(String? categoriaId) {
    if (state.categoriaId == categoriaId) return;
    _debounce?.cancel();
    state = state.copyWith(
      categoriaId: categoriaId,
      clearCategoriaId: categoriaId == null,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    unawaited(load());
  }

  void setFornecedorIdFilter(String? fornecedorId) {
    if (state.fornecedorId == fornecedorId) return;
    state = state.copyWith(
      fornecedorId: fornecedorId,
      clearFornecedorId: fornecedorId == null,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    unawaited(load());
  }

  void setTipoDispensacaoFilter(String? tipo) {
    if (state.tipoDispensacao == tipo) return;
    state = state.copyWith(
      tipoDispensacao: tipo,
      clearTipoDispensacao: tipo == null,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    unawaited(load());
  }

  void setAtivoFilter(bool? ativo) {
    if (state.ativoFilter == ativo &&
        state.includeInactive == (ativo == null)) {
      return;
    }
    state = state.copyWith(
      ativoFilter: ativo,
      clearAtivoFilter: ativo == null,
      includeInactive: ativo == null,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    unawaited(load());
  }

  void setSort(String sortBy, String sortOrder) {
    state = state.copyWith(
      sortBy: sortBy,
      sortOrder: sortOrder,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    unawaited(load());
  }

  void clearFilters() {
    if (!state.hasFilters) return;
    _debounce?.cancel();
    state = state.copyWith(
      clearAtivoFilter: true,
      clearCategoriaId: true,
      includeInactive: false,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    unawaited(load());
  }

  void setPageSize(int pageSize) {
    if (state.pageSize == pageSize) return;
    state = state.copyWith(pageSize: pageSize, page: 1, isLoading: true, clearError: true);
    unawaited(load());
  }

  void setIncludeInactive(bool value) {
    if (state.includeInactive == value) {
      return;
    }
    _debounce?.cancel();
    state = state.copyWith(
      includeInactive: value,
      page: 1,
      isLoading: true,
      clearError: true,
    );
    unawaited(load(force: true));
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page == state.page) {
      return;
    }
    state = state.copyWith(page: page, isLoading: true, clearError: true);
    await load();
  }

  Future<void> refreshCurrentPage() async {
    await load(force: true);
  }

  Future<void> load({bool force = false}) async {
    final requestId = ++_requestId;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(productRepositoryProvider);
      final isBarcode = _looksLikeBarcode(state.query);
      final response = await repository.searchMasterProducts(
        query: isBarcode ? null : (state.query.isEmpty ? null : state.query),
        barcode: isBarcode ? state.query : null,
        categoriaId: state.categoriaId,
        fornecedorId: state.fornecedorId,
        tipoDispensacao: state.tipoDispensacao,
        ativo: state.ativoFilter,
        includeInactive: state.includeInactive,
        sortBy: state.sortBy,
        sortOrder: state.sortOrder,
        page: state.page,
        pageSize: state.pageSize,
      );

      if (requestId != _requestId) {
        return;
      }

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

  Future<Product?> createProduct(Map<String, dynamic> payload) async {
    final repository = ref.read(productRepositoryProvider);
    final created = await repository.createProduct(payload);
    await load(force: true);
    return created;
  }

  Future<Product?> updateProduct(String id, Map<String, dynamic> payload) async {
    final repository = ref.read(productRepositoryProvider);
    final updated = await repository.updateProduct(id, payload);
    await load(force: true);
    var items = state.items;
    if (state.includeInactive &&
        !updated.ativo &&
        !items.any((item) => item.id == updated.id)) {
      items = <Product>[
        updated,
        ...items,
      ];
    }
    state = state.copyWith(
      items: items,
    );
    return updated;
  }

  Future<void> deleteProduct(String id) async {
    if (state.deletingProductIds.contains(id)) {
      return;
    }

    final repository = ref.read(productRepositoryProvider);
    state = state.copyWith(
      deletingProductIds: <String>{
        ...state.deletingProductIds,
        id,
      },
      clearError: true,
    );

    try {
      await repository.deleteProduct(id);
      await load(force: true);
      final items = state.items.where((item) => item.id != id).toList(growable: false);
      state = state.copyWith(
        items: items,
      );
    } finally {
      state = state.copyWith(
        deletingProductIds: state.deletingProductIds
            .where((productId) => productId != id)
            .toSet(),
      );
    }
  }

  bool _looksLikeBarcode(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 8) return false;
    return RegExp(r'^\d+$').hasMatch(trimmed);
  }
}

final masterProductListProvider =
    NotifierProvider<MasterProductListController, MasterProductListState>(
  MasterProductListController.new,
);
