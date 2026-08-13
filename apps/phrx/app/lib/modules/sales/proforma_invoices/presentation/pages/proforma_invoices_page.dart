import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/layout/enterprise_module_search_bar.dart';
import '../../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../../../../pharmacy/products/domain/entities/product.dart';
import '../../../../pharmacy/products/presentation/providers/product_provider.dart';
import '../../../../pharmacy/products/presentation/widgets/produto_categoria_filter_dropdown.dart';
import '../../../../reports/presentation/controllers/report_controller.dart';
import '../../../pdv/domain/entities/pdv_service.dart';
import '../../../pdv/presentation/providers/pdv_service_provider.dart';
import '../../../pdv/presentation/widgets/pdv_catalog_utils.dart';
import '../../../pdv/presentation/widgets/pdv_product_list.dart';
import '../../../pdv/presentation/widgets/pdv_product_table.dart';
import '../../../pdv/presentation/widgets/pdv_service_list.dart';
import '../../../pdv/presentation/widgets/pdv_service_table.dart';
import '../../domain/entities/proforma_invoice_cart_line.dart';
import '../providers/proforma_invoice_cart_provider.dart';
import '../widgets/proforma_invoice_cart_item_card.dart';
import '../widgets/proforma_invoice_cart_summary.dart';
import '../widgets/save_proforma_invoice_dialog.dart';
import '../../../../../shared/refresh/page_refresh.dart';

class SalesProformaInvoicesPage extends ConsumerStatefulWidget {
  const SalesProformaInvoicesPage({super.key});

  @override
  ConsumerState<SalesProformaInvoicesPage> createState() =>
      _SalesProformaInvoicesPageState();
}

class _SalesProformaInvoicesPageState
    extends ConsumerState<SalesProformaInvoicesPage>
    with TickerProviderStateMixin {
  final _search = TextEditingController();
  final _searchFocusNode = FocusNode();
  late final TabController _catalogTabController;
  int _catalogTabIndex = 0;
  List<Product> _accumulatedProducts = [];

  @override
  void initState() {
    super.initState();
    _catalogTabController = TabController(length: 3, vsync: this);
    _search.text = ref.read(productListProvider).query;
  }

  @override
  void dispose() {
    _catalogTabController.dispose();
    _search.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool get _isProductsTab => _catalogTabIndex == 0;
  bool get _isServicesTab => _catalogTabIndex == 1;
  bool get _isHistoryTab => _catalogTabIndex == 2;

  void _onCatalogTabSelected(int index) {
    if (_catalogTabIndex == index) {
      return;
    }
    setState(() => _catalogTabIndex = index);
    _syncSearchText(index);
  }

  void _syncSearchText(int index) {
    final query = index == 0
        ? ref.read(productListProvider).query
        : index == 1
        ? ref.read(pdvServiceListProvider).query
        : '';
    _search.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
  }

  void _onSearchChanged(String value) {
    if (_isProductsTab) {
      ref.read(productListProvider.notifier).onSearchChanged(value);
      return;
    }
    if (_isServicesTab) {
      ref.read(pdvServiceListProvider.notifier).onSearchChanged(value);
      return;
    }
    unawaited(
      ref.read(proformaInvoiceCartProvider.notifier).loadHistory(query: value),
    );
  }

  void _onCategoryChanged(String? categoriaId) {
    ref.read(productListProvider.notifier).setCategoriaFilter(categoriaId);
  }

  SaveProformaInvoiceDialogInitialData? _buildInitialHeaderData() {
    final cartState = ref.read(proformaInvoiceCartProvider);
    final validade =
        cartState.validade ?? DateTime.now().add(const Duration(days: 30));
    final cliente = cartState.cliente;
    if (cliente == null || cliente.isEmpty) {
      return null;
    }
    return SaveProformaInvoiceDialogInitialData(
      cliente: cliente,
      clienteId: cartState.clienteId,
      validade: validade,
      nuit: cartState.nuit,
      contacto: cartState.contacto,
      descontoGeral: cartState.descontoTotal,
      observacoes: cartState.observacoes,
    );
  }

  Future<void> _createProformaInvoiceForLine(
    ProformaInvoiceCartLine line,
  ) async {
    final result = await showSaveProformaInvoiceDialog(
      context,
      initialData: _buildInitialHeaderData(),
    );
    if (!mounted || result == null) {
      return;
    }
    try {
      await ref
          .read(proformaInvoiceCartProvider.notifier)
          .createProformaInvoice(header: result, initialLines: [line]);
      if (!mounted) {
        return;
      }
      final state = ref.read(proformaInvoiceCartProvider);
      PharmaFeedback.success(
        context,
        'Fatura Proforma ${state.proformaInvoiceNumero} criada e persistida no backend.',
      );
    } on ApiFailure catch (e) {
      if (mounted) {
        PharmaFeedback.error(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        PharmaFeedback.error(context, e.toString());
      }
    }
  }

  Future<void> _addProduct(Product product) async {
    final controller = ref.read(proformaInvoiceCartProvider.notifier);
    final state = ref.read(proformaInvoiceCartProvider);
    try {
      if (!state.hasProformaInvoice) {
        await _createProformaInvoiceForLine(
          ProformaInvoiceCartLine.fromProduct(product),
        );
        return;
      }
      await controller.addProduct(product);
      if (!mounted) {
        return;
      }
      PharmaFeedback.success(
        context,
        '${product.nomeComercial} adicionado à fatura proforma.',
      );
    } on ApiFailure catch (e) {
      if (mounted) {
        PharmaFeedback.error(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        PharmaFeedback.error(context, e.toString());
      }
    }
  }

  Future<void> _addService(PdvService service) async {
    final controller = ref.read(proformaInvoiceCartProvider.notifier);
    final state = ref.read(proformaInvoiceCartProvider);
    try {
      if (!state.hasProformaInvoice) {
        await _createProformaInvoiceForLine(
          ProformaInvoiceCartLine.fromService(service),
        );
        return;
      }
      await controller.addService(service);
      if (!mounted) {
        return;
      }
      PharmaFeedback.success(
        context,
        '${service.nome} adicionado à fatura proforma.',
      );
    } on ApiFailure catch (e) {
      if (mounted) {
        PharmaFeedback.error(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        PharmaFeedback.error(context, e.toString());
      }
    }
  }

  Future<void> _cancelProformaInvoice() async {
    final cart = ref.read(proformaInvoiceCartProvider);
    if (!cart.hasProformaInvoice) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar fatura proforma'),
        content: const Text(
          'Esta ação muda o estado para REJEITADA. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Fechar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await ref
          .read(proformaInvoiceCartProvider.notifier)
          .cancelProformaInvoice();
      if (!mounted) {
        return;
      }
      PharmaFeedback.success(context, 'Fatura Proforma cancelada.');
    } on ApiFailure catch (e) {
      if (mounted) {
        PharmaFeedback.error(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        PharmaFeedback.error(context, e.toString());
      }
    }
  }

  Future<void> _finalizeProformaInvoice() async {
    final cart = ref.read(proformaInvoiceCartProvider);
    final proformaInvoiceId = cart.proformaInvoiceId;
    if (proformaInvoiceId == null) {
      return;
    }
    try {
      if (cart.proformaInvoiceEstado == 'PENDENTE') {
        await ref
            .read(proformaInvoiceCartProvider.notifier)
            .approveProformaInvoice();
      }
      await ref
          .read(reportControllerProvider.notifier)
          .downloadPdf(
            path: '/tenant/proforma-invoices/$proformaInvoiceId/pdf',
          );
      if (!mounted) {
        return;
      }
      PharmaFeedback.success(
        context,
        'Fatura Proforma gerada para impressão (sem impacto de stock).',
      );
    } on ApiFailure catch (e) {
      if (mounted) {
        PharmaFeedback.error(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        PharmaFeedback.error(context, e.toString());
      }
    }
  }

  Widget _buildHistoryPane() {
    final state = ref.watch(proformaInvoiceCartProvider);
    final s = context.spacing;
    final t = context.pharmaTokens;
    if (state.isLoadingHistory && state.history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.history.isEmpty) {
      return const ModuleEmptyState(
        title: 'Sem histórico de faturas proforma',
        subtitle: 'As faturas proforma emitidas serão listadas aqui.',
      );
    }
    return ListView.separated(
      padding: EdgeInsets.all(s.md),
      itemCount: state.history.length,
      separatorBuilder: (_, _) => SizedBox(height: s.xs),
      itemBuilder: (context, index) {
        final item = state.history[index];
        return Card(
          color: t.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(t.radiusMd),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(t.radiusMd),
            onTap: () => unawaited(
              ref
                  .read(proformaInvoiceCartProvider.notifier)
                  .openProformaInvoice(item.id),
            ),
            child: Padding(
              padding: EdgeInsets.all(s.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.numero} • ${item.clienteNome}',
                          style: Theme.of(context).textTheme.erpLabel,
                        ),
                        SizedBox(height: s.xxs),
                        Text(
                          'Estado: ${item.estado} • Itens: ${item.itemCount}',
                          style: Theme.of(context).textTheme.erpCaption,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Imprimir Proforma',
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        onPressed: () => unawaited(
                          ref
                              .read(reportControllerProvider.notifier)
                              .downloadPdf(
                                path:
                                    '/tenant/proforma-invoices/${item.id}/pdf',
                              ),
                        ),
                      ),
                      Text(
                        item.total.toStringAsFixed(2),
                        style: Theme.of(context).textTheme.erpLabel,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSearchSubmitted({
    required List<Product> products,
    required List<PdvService> services,
    List<Product>? accumulatedProducts,
  }) async {
    if (_isProductsTab) {
      final catalogProducts = accumulatedProducts ?? products;
      if (catalogProducts.isEmpty) {
        return;
      }
      await _addProduct(catalogProducts.first);
      ref.read(productListProvider.notifier).onSearchChanged('');
    } else if (_isServicesTab) {
      if (services.isEmpty) {
        return;
      }
      await _addService(services.first);
      ref.read(pdvServiceListProvider.notifier).onSearchChanged('');
    } else {
      await ref
          .read(proformaInvoiceCartProvider.notifier)
          .loadHistory(query: _search.text);
    }
    _search.clear();
    _searchFocusNode.requestFocus();
  }

  Widget _buildCatalogPane({
    required bool isMobile,
    required bool isDesktop,
    required ProductListState productState,
    required ProductListController productController,
    required PdvServiceListState serviceState,
    required PdvServiceListController serviceController,
    required List<Product> displayProducts,
    required bool activeIsLoading,
    required bool activeIsInitialized,
    required bool activeHasItems,
    required String? activeErrorMessage,
    required double bottomPadding,
  }) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final showCatalogPagination = !isMobile;

    if (!_isHistoryTab &&
        activeIsLoading &&
        !activeIsInitialized &&
        !activeHasItems) {
      return const ModuleLoadingState(itemCount: 4);
    }

    if (!_isHistoryTab && activeErrorMessage != null && !activeHasItems) {
      return ModuleErrorState(
        title: _isProductsTab
            ? 'Falha ao carregar produtos'
            : 'Falha ao carregar serviços',
        message: activeErrorMessage,
        onRetry: _isProductsTab
            ? productController.refreshCurrentPage
            : serviceController.refreshCurrentQuery,
        icon: Icons.error_outline,
      );
    }

    final catalogFooter = !_isHistoryTab && showCatalogPagination
        ? EnterprisePagination(
            page: _isProductsTab ? productState.page : serviceState.page,
            pageSize: _isProductsTab
                ? productState.pageSize
                : serviceState.pageSize,
            totalCount: _isProductsTab
                ? productState.totalCount
                : serviceState.totalCount,
            hasMore: _isProductsTab
                ? productState.hasMore
                : serviceState.hasMore,
            itemsOnPage: _isProductsTab
                ? productState.items.length
                : serviceState.items.length,
            isBusy: _isProductsTab
                ? productState.isLoading
                : serviceState.isLoading,
            itemLabel: _isProductsTab ? 'produtos' : 'serviços',
            onPageChanged: _isProductsTab
                ? productController.goToPage
                : serviceController.goToPage,
            onPageSizeChanged: _isProductsTab
                ? productController.setPageSize
                : serviceController.setPageSize,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (activeIsLoading)
          Padding(
            padding: EdgeInsets.only(bottom: s.sm),
            child: LinearProgressIndicator(minHeight: s.xxs),
          ),
        if (activeErrorMessage != null && activeHasItems)
          Padding(
            padding: EdgeInsets.only(bottom: s.sm),
            child: Material(
              color: t.posDanger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(t.radiusMd),
              child: Padding(
                padding: EdgeInsets.all(s.sm),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: t.posDanger,
                      size: t.iconSm,
                    ),
                    SizedBox(width: s.sm),
                    Expanded(
                      child: Text(
                        activeErrorMessage,
                        style: Theme.of(context).textTheme.erpBodySecondary
                            .copyWith(color: t.textPrimary),
                      ),
                    ),
                    TextButton(
                      onPressed: _isProductsTab
                          ? productController.refreshCurrentPage
                          : serviceController.refreshCurrentQuery,
                      child: const Text('Repetir'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Material(
          color: Colors.transparent,
          child: TabBar(
            controller: _catalogTabController,
            onTap: _onCatalogTabSelected,
            labelColor: t.textPrimary,
            unselectedLabelColor: t.textMuted,
            indicatorColor: t.brandBlue,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Lista de Produtos'),
              Tab(text: 'Serviços'),
              Tab(text: 'Histórico'),
            ],
          ),
        ),
        SizedBox(height: isMobile ? s.sm : s.md),
        if (!_isHistoryTab)
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth =
                  constraints.maxWidth.isFinite && constraints.maxWidth > 0
                  ? constraints.maxWidth
                  : MediaQuery.sizeOf(context).width;
              final categoryWidth = (availableWidth * 0.28).clamp(180.0, 280.0);

              final searchBar = EnterpriseModuleSearchBar(
                controller: _search,
                focusNode: _searchFocusNode,
                autofocus: true,
                hintText: _isProductsTab
                    ? (isMobile
                          ? 'Pesquisar ou escanear...'
                          : 'Pesquisar por código, nome ou EAN')
                    : (isMobile
                          ? 'Pesquisar serviço...'
                          : 'Pesquisar por nome do serviço'),
                enabled: !activeIsLoading,
                onSubmitted: (_) => _onSearchSubmitted(
                  products: productState.items,
                  services: serviceState.items,
                  accumulatedProducts: displayProducts,
                ),
                onChanged: _onSearchChanged,
              );

              final categoryFilter = ProdutoCategoriaFilterDropdown(
                value: productState.categoriaId,
                width: isMobile ? double.infinity : categoryWidth,
                enabled: !productState.isLoading,
                compact: true,
                emptyLabel: 'Todas',
                onChanged: _onCategoryChanged,
              );

              if (isMobile) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: t.controlHeight, child: searchBar),
                    if (_isProductsTab) ...[
                      SizedBox(height: s.sm),
                      SizedBox(height: t.controlHeight, child: categoryFilter),
                    ],
                  ],
                );
              }

              return SizedBox(
                height: t.controlHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: searchBar,
                    ),
                    if (_isProductsTab) ...[
                      SizedBox(width: s.sm),
                      SizedBox(
                        width: categoryWidth,
                        height: t.controlHeight,
                        child: categoryFilter,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        if (_isHistoryTab)
          EnterpriseModuleSearchBar(
            controller: _search,
            focusNode: _searchFocusNode,
            hintText: 'Pesquisar histórico de faturas proforma...',
            onSubmitted: (_) => _onSearchSubmitted(
              products: productState.items,
              services: serviceState.items,
            ),
            onChanged: _onSearchChanged,
          ),
        SizedBox(height: isMobile ? s.sm : s.md),
        Expanded(
          child: _isProductsTab
              ? isMobile
                    ? PdvProductList(
                        items: displayProducts,
                        query: productState.query,
                        hasMore: productState.hasMore,
                        isLoading: productState.isLoading,
                        canAdd: true,
                        addingProductId: null,
                        onAdd: (product) => unawaited(_addProduct(product)),
                        onLoadMore: () =>
                            productController.goToPage(productState.page + 1),
                        bottomPadding: bottomPadding,
                      )
                    : PdvProductTable(
                        items: productState.items,
                        query: productState.query,
                        canAdd: true,
                        addingProductId: null,
                        onAdd: (product) => unawaited(_addProduct(product)),
                        pagination: catalogFooter,
                      )
              : _isServicesTab
              ? isMobile
                    ? PdvServiceList(
                        items: serviceState.items,
                        query: serviceState.query,
                        canAdd: true,
                        onAdd: (service) => unawaited(_addService(service)),
                        bottomPadding: bottomPadding,
                      )
                    : PdvServiceTable(
                        items: serviceState.items,
                        query: serviceState.query,
                        canAdd: true,
                        onAdd: (service) => unawaited(_addService(service)),
                        pagination: catalogFooter,
                      )
              : _buildHistoryPane(),
        ),
      ],
    );
  }

  Widget _buildCartPane({required bool compact}) {
    final cartState = ref.watch(proformaInvoiceCartProvider);
    final controller = ref.read(proformaInvoiceCartProvider.notifier);
    final t = context.pharmaTokens;
    final s = context.spacing;
    final pad = compact ? EdgeInsets.zero : t.density.cardPadding;

    final canCancel =
        cartState.hasProformaInvoice &&
        !cartState.isBusy &&
        cartState.proformaInvoiceEstado == 'PENDENTE';
    final canFinalize =
        cartState.hasProformaInvoice &&
        !cartState.isBusy &&
        !cartState.isEmpty &&
        (cartState.proformaInvoiceEstado == 'PENDENTE' ||
            cartState.proformaInvoiceEstado == 'APROVADA');

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: pad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (cartState.hasProformaInvoice)
              Padding(
                padding: EdgeInsets.only(bottom: s.sm),
                child: Text(
                  'Proforma ${cartState.proformaInvoiceNumero} (${cartState.proformaInvoiceEstado})',
                  style: Theme.of(
                    context,
                  ).textTheme.erpLabel.copyWith(color: t.textSecondary),
                ),
              ),
            Expanded(
              child: cartState.isEmpty
                  ? const ModuleEmptyState(
                      title: 'Fatura Proforma vazia',
                      subtitle:
                          'Selecione uma fatura no histórico ou adicione produtos/serviços.',
                    )
                  : ListView.separated(
                      itemCount: cartState.lines.length,
                      separatorBuilder: (_, _) => SizedBox(height: s.sm),
                      itemBuilder: (context, index) {
                        final line = cartState.lines[index];
                        return ProformaInvoiceCartItemCard(
                          key: ValueKey(line.proformaInvoiceItemId ?? line.id),
                          line: line,
                          onChanged: (updated) =>
                              unawaited(controller.updateLine(updated)),
                          onIncrement: () =>
                              unawaited(controller.incrementLine(line)),
                          onDecrement: () =>
                              unawaited(controller.decrementLine(line)),
                          onRemove: () =>
                              unawaited(controller.removeLine(line)),
                        );
                      },
                    ),
            ),
            ProformaInvoiceCartSummary(
              itemCount: cartState.itemCount,
              subtotal: cartState.subtotal,
              descontoTotal: cartState.descontoTotal,
              ivaTotal: cartState.ivaTotal,
              total: cartState.total,
              action: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: canCancel
                          ? () => unawaited(_cancelProformaInvoice())
                          : null,
                      child: const Text('Cancelar'),
                    ),
                  ),
                  SizedBox(width: s.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: canFinalize
                          ? () => unawaited(_finalizeProformaInvoice())
                          : null,
                      child: Text(
                        compact ? 'Finalizar' : 'Finalizar Proforma',
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMobileCart() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          backgroundColor: context.pharmaTokens.bgPrimary,
          appBar: AppBar(
            leading: BackButton(onPressed: () => Navigator.of(context).pop()),
            title: const Text('Fatura Proforma'),
          ),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(context.spacing.md),
              child: _buildCartPane(compact: true),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final w = MediaQuery.sizeOf(context).width;
    final isDesktop = w > 1200;
    final isTablet = w > 700 && w <= 1200;
    final isMobile = w <= 700;

    final productState = ref.watch(productListProvider);
    final productController = ref.read(productListProvider.notifier);
    final serviceState = ref.watch(pdvServiceListProvider);
    final serviceController = ref.read(pdvServiceListProvider.notifier);
    final cartState = ref.watch(proformaInvoiceCartProvider);

    ref.listen<ProductListState>(productListProvider, (prev, next) {
      if (prev?.page != next.page ||
          prev?.query != next.query ||
          prev?.categoriaId != next.categoriaId) {
        if (next.page == 1) {
          _accumulatedProducts = List.of(next.items);
        } else {
          final newItems = next.items
              .where((e) => !_accumulatedProducts.any((a) => a.id == e.id))
              .toList();
          _accumulatedProducts.addAll(newItems);
        }
      } else if (prev?.items != next.items && next.page == 1) {
        _accumulatedProducts = List.of(next.items);
      }
    });

    final displayProducts = isMobile
        ? (_accumulatedProducts.isEmpty
              ? productState.items
              : _accumulatedProducts)
        : productState.items;

    final activeIsLoading = _isProductsTab
        ? productState.isLoading
        : serviceState.isLoading;
    final activeIsInitialized = _isProductsTab
        ? productState.isInitialized
        : serviceState.isInitialized;
    final activeHasItems = _isProductsTab
        ? productState.items.isNotEmpty
        : serviceState.items.isNotEmpty;
    final activeErrorMessage = _isProductsTab
        ? productState.errorMessage
        : serviceState.errorMessage;

    final catalogPane = _buildCatalogPane(
      isMobile: isMobile,
      isDesktop: isDesktop,
      productState: productState,
      productController: productController,
      serviceState: serviceState,
      serviceController: serviceController,
      displayProducts: displayProducts,
      activeIsLoading: activeIsLoading,
      activeIsInitialized: activeIsInitialized,
      activeHasItems: activeHasItems,
      activeErrorMessage: activeErrorMessage,
      bottomPadding: isMobile ? (t.controlHeight + s.xl) : 0,
    );

    final cartPane = _buildCartPane(compact: isMobile || isTablet);

    Future<void> refreshCatalog() async {
      if (_isProductsTab) {
        await productController.refreshCurrentPage();
      } else if (!_isHistoryTab) {
        await serviceController.refreshCurrentQuery();
      }
    }

    final Widget content;
    if (isDesktop) {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 5, child: catalogPane),
          SizedBox(width: s.md),
          VerticalDivider(width: 1, thickness: 1, color: t.border),
          SizedBox(width: s.md),
          SizedBox(width: 560, child: cartPane),
        ],
      );
    } else {
      content = Stack(
        children: [
          catalogPane,
          Positioned(
            right: s.xs,
            bottom: s.md,
            child: SafeArea(
              minimum: EdgeInsets.only(bottom: s.xs),
              child: FloatingActionButton.extended(
                onPressed: _showMobileCart,
                icon: Icon(Icons.receipt_long_rounded, size: t.iconSm),
                label: Text(
                  '${cartState.itemCount} Itens • ${pdvFormatMoney(cartState.total)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                extendedPadding: EdgeInsets.symmetric(horizontal: s.md),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: t.brandGreen,
              ),
            ),
          ),
        ],
      );
    }

    return PageRefreshBinder(onRefresh: refreshCatalog, child: content);
  }
}
