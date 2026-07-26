import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/widgets/buttons/pharma_button_loader.dart';
import '../../../../../shared/widgets/dialogs/enterprise_dialog.dart';
import '../../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/layout/enterprise_module_search_bar.dart';
import '../../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../../../../../shared/responsive/pharma_screen_layout.dart';
import '../../../../pharmacy/products/presentation/widgets/produto_categoria_filter_dropdown.dart';
import '../../../../pharmacy/products/domain/entities/product.dart';
import '../../../../pharmacy/products/presentation/providers/product_provider.dart';
import '../../../invoices/presentation/providers/invoice_action_provider.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../domain/entities/pdv_cart_line.dart';
import '../../domain/entities/pdv_checkout.dart';
import '../../domain/entities/pdv_service.dart';
import '../providers/caixa_sessao_provider.dart';
import '../providers/pdv_cart_provider.dart';
import '../providers/pdv_service_provider.dart';
import '../widgets/abrir_caixa_dialog.dart';
import '../widgets/finalizar_venda_dialog.dart';
import '../widgets/pdv_catalog_utils.dart';
import '../widgets/pdv_product_list.dart';
import '../widgets/pdv_product_table.dart';
import '../widgets/pdv_service_list.dart';
import '../widgets/pdv_service_table.dart';

class PdvPage extends ConsumerStatefulWidget {
  const PdvPage({super.key});

  @override
  ConsumerState<PdvPage> createState() => _PdvPageState();
}

class _PdvPageState extends ConsumerState<PdvPage>
    with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  final _searchFocusNode = FocusNode();
  late final TabController _catalogTabController;
  int _catalogTabIndex = 0;
  List<Product> _accumulatedProducts = [];

  @override
  void initState() {
    super.initState();
    _catalogTabController = TabController(length: 2, vsync: this);
    _search.text = ref.read(productListProvider).query;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(pdvCartProvider.notifier).ensureLoaded();
    });
  }

  @override
  void dispose() {
    _catalogTabController.dispose();
    _search.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool get _isProductsTab => _catalogTabIndex == 0;

  void _onCatalogTabSelected(int index) {
    if (_catalogTabIndex == index) {
      return;
    }
    setState(() {
      _catalogTabIndex = index;
    });
    _syncSearchText(index);
  }

  void _syncSearchText(int index) {
    final query = index == 0
        ? ref.read(productListProvider).query
        : ref.read(pdvServiceListProvider).query;
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
    ref.read(pdvServiceListProvider.notifier).onSearchChanged(value);
  }

  void _onCategoryChanged(String? categoriaId) {
    ref.read(productListProvider.notifier).setCategoriaFilter(categoriaId);
  }

  Future<void> _openAbrirCaixaDialog() {
    return showAbrirCaixaDialog(context);
  }

  bool _ensureCaixaAberto() {
    if (ref.read(caixaSessaoProvider).hasSessaoAberta) {
      return true;
    }
    unawaited(_openAbrirCaixaDialog());
    return false;
  }

  Future<void> _onSearchSubmitted({
    required List<Product> products,
    required List<PdvService> services,
    List<Product>? accumulatedProducts,
  }) async {
    if (!_ensureCaixaAberto()) {
      return;
    }

    if (_isProductsTab) {
      final catalogProducts = accumulatedProducts ?? products;
      if (catalogProducts.isEmpty) {
        return;
      }
      final added = await _addProduct(catalogProducts.first);
      if (!added || !mounted) {
        return;
      }
      ref.read(productListProvider.notifier).onSearchChanged('');
    } else {
      if (services.isEmpty) {
        return;
      }
      final addedService = await _addService(services.first);
      if (!addedService || !mounted) {
        return;
      }
      ref.read(pdvServiceListProvider.notifier).onSearchChanged('');
    }
    _search.clear();
    _searchFocusNode.requestFocus();
  }

  Future<bool> _addProduct(Product p) async {
    if (!_ensureCaixaAberto()) {
      return false;
    }

    if (ref.read(pdvCartProvider).isMutating) {
      return false;
    }

    try {
      final added = await ref.read(pdvCartProvider.notifier).addProduct(p);
      if (!mounted) {
        return false;
      }
      if (added) {
        PharmaFeedback.success(
          context,
          '${p.nomeComercial} adicionado ao carrinho.',
        );
      }
      return added;
    } on ApiFailure catch (e) {
      if (mounted) {
        PharmaFeedback.error(context, e.message);
      }
      return false;
    } catch (_) {
      if (mounted) {
        PharmaFeedback.error(
          context,
          'Falha ao adicionar produto. Tente novamente.',
        );
      }
      return false;
    }
  }

  Future<bool> _addService(PdvService service) async {
    if (!_ensureCaixaAberto()) {
      return false;
    }

    if (ref.read(pdvCartProvider).isMutating) {
      return false;
    }

    try {
      final added = await ref.read(pdvCartProvider.notifier).addService(service);
      if (!mounted) {
        return false;
      }
      if (added) {
        PharmaFeedback.success(
          context,
          '${service.nome} adicionado ao carrinho.',
        );
      }
      return added;
    } on ApiFailure catch (e) {
      if (mounted) {
        PharmaFeedback.error(context, e.message);
      }
      return false;
    } catch (_) {
      if (mounted) {
        PharmaFeedback.error(
          context,
          'Falha ao adicionar serviço. Tente novamente.',
        );
      }
      return false;
    }
  }

  Future<void> _mutateCart(Future<bool> Function() action) async {
    try {
      await action();
    } on ApiFailure catch (e) {
      if (mounted) {
        PharmaFeedback.error(context, e.message);
      }
    } catch (_) {
      if (mounted) {
        PharmaFeedback.error(
          context,
          'Falha ao atualizar o carrinho. Tente novamente.',
        );
      }
    }
  }

  Future<void> _addLine(PdvCartLine line) async {
    if (!_ensureCaixaAberto()) {
      return;
    }
    if (line.canMutateViaApi) {
      await _mutateCart(() => ref.read(pdvCartProvider.notifier).incrementLine(line));
      return;
    }
    if (line.service != null) {
      await _addService(line.service!);
      return;
    }
    if (line.product != null) {
      await _addProduct(line.product!);
    }
  }

  Future<void> _removeLine(PdvCartLine line) async {
    if (!_ensureCaixaAberto()) {
      return;
    }
    await _mutateCart(() => ref.read(pdvCartProvider.notifier).decrementLine(line));
  }

  Future<void> _deleteLine(PdvCartLine line) async {
    if (!_ensureCaixaAberto()) {
      return;
    }
    await _mutateCart(() => ref.read(pdvCartProvider.notifier).removeLine(line));
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.f2) {
        _searchFocusNode.requestFocus();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _search.clear();
        _onSearchChanged('');
      }
    }
  }

  void _showMobileCart() {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => _MobileCartScreen(
            onCharge: _handleCheckout,
            onCancelCart: _handleCancelCart,
            onAdd: _addLine,
            onRemove: _removeLine,
            onDelete: _deleteLine,
          ),
        ),
      ),
    );
  }

  Future<void> _handleCancelCart() async {
    if (!_ensureCaixaAberto()) {
      return;
    }

    final cartState = ref.read(pdvCartProvider);
    if (cartState.lines.isEmpty) {
      return;
    }

    final confirm = await PharmaFeedback.confirm(
      context: context,
      title: 'Cancelar Venda',
      message: 'Tem certeza que deseja cancelar a venda atual e limpar o carrinho?',
      confirmText: 'Sim, Cancelar',
      cancelText: 'Não, Continuar',
      destructive: true,
    );

    if (confirm != true || !mounted) {
      return;
    }

    try {
      ref.read(pdvCartProvider.notifier).clear();
      // O carrinho local é limpo imediatamente. Opcionalmente, pode notificar o backend para limpar o idempotencyKey ativo
      PharmaFeedback.success(context, 'Venda cancelada e carrinho limpo.');
    } catch (_) {
      if (mounted) {
        PharmaFeedback.error(context, 'Falha ao cancelar venda.');
      }
    }
  }

  Future<void> _handleCheckout() async {
    if (!_ensureCaixaAberto()) {
      return;
    }

    final cartState = ref.read(pdvCartProvider);
    if (cartState.lines.isEmpty) {
      return;
    }

    final result = await showFinalizarVendaDialog(
      context,
      total: cartState.total,
      requiresPatientDetails: cartState.requiresPatientDetails,
    );

    if (!mounted || result == null) {
      return;
    }

    PharmaFeedback.success(
      context,
      'Pagamento confirmado. Fatura ${result.numero} — total ${pdvFormatMoney(result.total)} (valores do servidor).',
    );

    await _showCheckoutActions(result);
  }

  Future<void> _showCheckoutActions(PdvCheckoutResult result) async {
    final isMobile = MediaQuery.sizeOf(context).width < Breakpoints.tablet;
    final isThermal = result.isThermalReceipt;
    final actions = <Widget>[
      if (!isMobile)
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      OutlinedButton.icon(
        onPressed: () async {
          Navigator.of(context).pop();
          try {
            await ref.read(invoiceActionProvider.notifier).showDocument(
                  invoiceId: result.id,
                  tipo: result.tipo,
                  previewContext: context,
                );
            if (!mounted) {
              return;
            }
            PharmaFeedback.success(
              context,
              isThermal
                  ? 'PDF do recibo 80mm disponibilizado.'
                  : 'PDF A4 da fatura disponibilizado.',
            );
          } on ApiFailure catch (e) {
            if (!mounted) {
              return;
            }
            PharmaFeedback.error(context, e.message);
          } catch (_) {
            if (!mounted) {
              return;
            }
            PharmaFeedback.error(
              context,
              isThermal
                  ? 'Não foi possível mostrar o recibo 80mm.'
                  : 'Não foi possível abrir o PDF A4.',
            );
          }
        },
        icon: Icon(
          isThermal ? Icons.receipt_long_outlined : Icons.picture_as_pdf_outlined,
        ),
        label: Text(isThermal ? 'Ver PDF 80mm' : 'Ver PDF A4'),
      ),
      FilledButton.icon(
        onPressed: () async {
          Navigator.of(context).pop();
          try {
            await ref.read(invoiceActionProvider.notifier).printReceipt(
                  invoiceId: result.id,
                  tipo: result.tipo,
                  previewContext: context,
                );
            if (!mounted) {
              return;
            }
            PharmaFeedback.success(
              context,
              isThermal
                  ? 'Impressão térmica 80mm preparada.'
                  : 'PDF A4 pronto para imprimir.',
            );
          } on ApiFailure catch (e) {
            if (!mounted) {
              return;
            }
            PharmaFeedback.error(context, e.message);
          } catch (_) {
            if (!mounted) {
              return;
            }
            PharmaFeedback.error(
              context,
              isThermal
                  ? 'Não foi possível imprimir o recibo 80mm.'
                  : 'Não foi possível preparar o PDF A4.',
            );
          }
        },
        icon: const Icon(Icons.print_outlined),
        label: Text(isThermal ? 'Imprimir 80mm' : 'Imprimir A4'),
      ),
    ];

    await showEnterpriseDialog<void>(
      context: context,
      title: Text(isThermal ? 'Recibo emitido (FR)' : 'Fatura emitida (FT)'),
      body: Text(
        isThermal
            ? 'A fatura-recibo ${result.numero} foi emitida. Deseja abrir o PDF 80mm ou imprimir na térmica?'
            : 'A fatura ${result.numero} foi emitida. Deseja abrir ou imprimir o PDF A4?',
      ),
      scrollable: false,
      showClose: isMobile,
      actions: actions,
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
    final showCatalogPagination = !context.isMobile;
    final productState = ref.watch(productListProvider);
    final productController = ref.read(productListProvider.notifier);
    final serviceState = ref.watch(pdvServiceListProvider);
    final serviceController = ref.read(pdvServiceListProvider.notifier);
    final caixaState = ref.watch(caixaSessaoProvider);
    final caixaAberto = caixaState.hasSessaoAberta;
    final cartState = ref.watch(pdvCartProvider);
    final cart = cartState.lines;
    final cartItemCount =
        cart.fold<int>(0, (sum, line) => sum + line.qty);
    final mobileCartButtonHeight = t.controlHeight;
    final mobileFooterHeightEstimate = t.controlHeight + s.lg;
    final mobileCartFooterGap = s.sm;
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
        ? (_accumulatedProducts.isEmpty ? productState.items : _accumulatedProducts)
        : productState.items;
    final canAddCatalog =
        caixaAberto && !cartState.isMutating && !cartState.isLoading;
    final catalogListBottomPadding = isMobile ? mobileCartButtonHeight + s.xl : 0.0;

    if (activeIsLoading && !activeIsInitialized && !activeHasItems) {
      return const ModuleLoadingState(itemCount: 4);
    }

    if (activeErrorMessage != null && !activeHasItems) {
      return ModuleErrorState(
        title: _isProductsTab ? 'Falha ao carregar produtos' : 'Falha ao carregar serviços',
        message: activeErrorMessage,
        onRetry: _isProductsTab
            ? productController.refreshCurrentPage
            : serviceController.refreshCurrentQuery,
        icon: Icons.error_outline,
      );
    }

    final catalogFooter = EnterprisePagination(
      page: _isProductsTab ? productState.page : serviceState.page,
      pageSize: _isProductsTab ? productState.pageSize : serviceState.pageSize,
      totalCount: _isProductsTab ? productState.totalCount : serviceState.totalCount,
      hasMore: _isProductsTab ? productState.hasMore : serviceState.hasMore,
      itemsOnPage:
          _isProductsTab ? productState.items.length : serviceState.items.length,
      isBusy: _isProductsTab ? productState.isLoading : serviceState.isLoading,
      itemLabel: _isProductsTab ? 'produtos' : 'serviços',
      onPageChanged: _isProductsTab
          ? productController.goToPage
          : serviceController.goToPage,
      onPageSizeChanged: _isProductsTab
          ? productController.setPageSize
          : serviceController.setPageSize,
    );

    final catalog = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!caixaAberto)
          Padding(
            padding: EdgeInsets.only(bottom: s.md),
            child: CaixaFechadoBanner(
              onAbrirCaixa: () => unawaited(_openAbrirCaixaDialog()),
            ),
          ),
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
                    Icon(Icons.error_outline, color: t.posDanger, size: t.iconSm),
                    SizedBox(width: s.sm),
                    Expanded(
                      child: Text(
                        activeErrorMessage,
                        style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textPrimary),
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
            ],
          ),
        ),
        SizedBox(height: isMobile ? s.sm : s.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            
            final columns = PharmaScreenLayout.adaptiveCrossAxisCount(
              availableWidth,
              280,
              maxColumns: availableWidth >= 1440 ? 5 : 4,
            );
            final fieldWidth = ((availableWidth - (columns - 1) * s.sm) / columns).clamp(220.0, 360.0);

            Widget filterField(Widget child) => SizedBox(
                  width: isMobile ? double.infinity : fieldWidth,
                  height: t.controlHeight,
                  child: child,
                );

            final searchBar = EnterpriseModuleSearchBar(
              controller: _search,
              focusNode: _searchFocusNode,
              autofocus: true,
              hintText: _isProductsTab
                  ? (isMobile ? 'Pesquisar ou escanear...' : 'Pesquisar por código, nome ou EAN')
                  : (isMobile ? 'Pesquisar serviço...' : 'Pesquisar por nome do serviço'),
              enabled: true,
              onSubmitted: (_) => _onSearchSubmitted(
                products: productState.items,
                services: serviceState.items,
                accumulatedProducts: displayProducts,
              ),
              onChanged: _onSearchChanged,
            );

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  filterField(searchBar),
                  if (_isProductsTab) ...[
                    SizedBox(height: s.sm),
                    filterField(
                      ProdutoCategoriaFilterDropdown(
                        value: productState.categoriaId,
                        width: double.infinity,
                        enabled: true,
                        onChanged: _onCategoryChanged,
                      ),
                    ),
                  ],
                ],
              );
            }

            return Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: t.controlHeight,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      filterField(searchBar),
                      if (_isProductsTab) ...[
                        SizedBox(width: s.sm),
                        filterField(
                          ProdutoCategoriaFilterDropdown(
                            value: productState.categoriaId,
                            width: null,
                            enabled: true,
                            onChanged: _onCategoryChanged,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
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
                      canAdd: canAddCatalog,
                      addingProductId: cartState.busyLineId,
                      onAdd: (product) => unawaited(_addProduct(product)),
                      onLoadMore: () =>
                          productController.goToPage(productState.page + 1),
                      bottomPadding: catalogListBottomPadding,
                    )
                  : PdvProductTable(
                      items: productState.items,
                      query: productState.query,
                      canAdd: canAddCatalog,
                      addingProductId: cartState.busyLineId,
                      onAdd: (product) => unawaited(_addProduct(product)),
                    )
              : isMobile
                  ? PdvServiceList(
                      items: serviceState.items,
                      query: serviceState.query,
                      canAdd: canAddCatalog,
                      onAdd: (service) => unawaited(_addService(service)),
                      bottomPadding: catalogListBottomPadding,
                    )
                  : PdvServiceTable(
                      items: serviceState.items,
                      query: serviceState.query,
                      canAdd: canAddCatalog,
                      onAdd: (service) => unawaited(_addService(service)),
                    ),
        ),
        if (showCatalogPagination) ...[
          SizedBox(height: s.sm),
          catalogFooter,
        ],
      ],
    );
    final mobileCatalog = isMobile ? catalog : catalog;

    final cartPane = _CartPane(
      subtotal: cartState.subtotal,
      tax: cartState.tax,
      taxLabel: cartState.taxLabel,
      discount: cartState.discount,
      total: cartState.total,
      cart: cart,
      t: t,
      compact: isMobile || isTablet,
      caixaAberto: caixaAberto,
      isCartBusy: cartState.isMutating || cartState.isLoading,
      onCharge: (!caixaAberto || cart.isEmpty) ? null : _handleCheckout,
      onCancelCart: (!caixaAberto || cart.isEmpty) ? null : _handleCancelCart,
      onAdd: (line) => unawaited(_addLine(line)),
      onRemove: (line) => unawaited(_removeLine(line)),
      onDelete: (line) => unawaited(_deleteLine(line)),
      isLineBusy: cartState.isLineBusy,
    );

        Widget content;
        if (isDesktop) {
          content = Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: catalog),
              SizedBox(width: s.lg),
              SizedBox(
                width: 560,
                child: cartPane,
              ),
            ],
          );
        } else {
          content = Stack(
            children: [
              Column(
                children: [
                  Expanded(child: mobileCatalog),
                ],
              ),
              Positioned(
                right: s.xs,
                bottom: mobileFooterHeightEstimate + mobileCartFooterGap,
                child: SafeArea(
                  minimum: EdgeInsets.only(bottom: s.xs),
                  child: SizedBox(
                    height: mobileCartButtonHeight,
                    child: FloatingActionButton.extended(
                      onPressed: _showMobileCart,
                      icon: Icon(
                        Icons.shopping_cart_rounded,
                        size: t.iconSm,
                      ),
                      label: Text(
                        '$cartItemCount Itens • ${pdvFormatMoney(cartState.total)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      extendedPadding: EdgeInsets.symmetric(horizontal: s.md),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: t.brandGreen,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: _handleKeyEvent,
          child: content,
        );
  }
}

class _MobileCartScreen extends ConsumerWidget {
  const _MobileCartScreen({
    required this.onCharge,
    required this.onCancelCart,
    required this.onAdd,
    required this.onRemove,
    required this.onDelete,
  });

  final Future<void> Function() onCharge;
  final Future<void> Function() onCancelCart;
  final Future<void> Function(PdvCartLine line) onAdd;
  final Future<void> Function(PdvCartLine line) onRemove;
  final Future<void> Function(PdvCartLine line) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final caixaAberto = ref.watch(caixaSessaoProvider).hasSessaoAberta;
    final cartState = ref.watch(pdvCartProvider);
    final cart = cartState.lines;

    return Scaffold(
      backgroundColor: t.bgPrimary,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Carrinho Atual'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(s.md),
          child: _CartPane(
            subtotal: cartState.subtotal,
            tax: cartState.tax,
            taxLabel: cartState.taxLabel,
            discount: cartState.discount,
            total: cartState.total,
            cart: cart,
            t: t,
            compact: true,
            caixaAberto: caixaAberto,
            isCartBusy: cartState.isMutating || cartState.isLoading,
            onCharge: (!caixaAberto || cart.isEmpty)
                ? null
                : () {
                    unawaited(onCharge());
                  },
            onCancelCart: (!caixaAberto || cart.isEmpty)
                ? null
                : () {
                    unawaited(onCancelCart());
                  },
            onAdd: (line) => unawaited(onAdd(line)),
            onRemove: (line) => unawaited(onRemove(line)),
            onDelete: (line) => unawaited(onDelete(line)),
            isLineBusy: cartState.isLineBusy,
          ),
        ),
      ),
    );
  }
}

class _CartPane extends StatelessWidget {
  const _CartPane({
    required this.subtotal,
    required this.tax,
    required this.taxLabel,
    required this.discount,
    required this.total,
    required this.cart,
    required this.t,
    required this.compact,
    required this.caixaAberto,
    required this.isCartBusy,
    required this.onCharge,
    this.onCancelCart,
    required this.onAdd,
    required this.onRemove,
    required this.onDelete,
    required this.isLineBusy,
  });

  final double subtotal;
  final double tax;
  final String taxLabel;
  final double discount;
  final double total;
  final List<PdvCartLine> cart;
  final PharmaTokens t;
  final bool compact;
  final bool caixaAberto;
  final bool isCartBusy;
  final VoidCallback? onCharge;
  final VoidCallback? onCancelCart;
  final void Function(PdvCartLine) onAdd;
  final void Function(PdvCartLine) onRemove;
  final void Function(PdvCartLine) onDelete;
  final bool Function(String lineId) isLineBusy;

  Widget _buildLineTitle(BuildContext context, PdvCartLine line) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final textTheme = Theme.of(context).textTheme;
    final product = line.product;

    if (product == null) {
      return Text(
        line.nome,
        style: textTheme.erpTablePrimary.copyWith(color: t.textPrimary),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    final substancia = product.nomeGenerico?.trim();
    final title = pdvProductDisplayTitle(
      nomeComercial: product.nomeComercial,
      dosagem: product.dosagem,
      forma: product.forma,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: textTheme.erpTablePrimary.copyWith(color: t.textPrimary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (substancia != null && substancia.isNotEmpty) ...[
          SizedBox(height: s.xxs),
          Text(
            substancia,
            style: textTheme.erpTableMeta.copyWith(color: t.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final pad = compact ? EdgeInsets.all(s.md) : t.density.cardPadding;
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: pad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: cart.isEmpty
                  ? const ModuleEmptyState(
                      title: 'Carrinho vazio',
                      subtitle: 'Escaneie ou pesquise um produto ou serviço',
                    )
                  : ListView.separated(
                      itemCount: cart.length,
                      separatorBuilder: (_, _) => Divider(color: t.border.withValues(alpha: 0.3)),
                      itemBuilder: (context, i) {
                        final line = cart[i];
                        final lineBusy = isLineBusy(line.id);
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: s.xs),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLineTitle(context, line),
                                    SizedBox(height: s.xxs),
                                    Text(
                                      '${pdvFormatMoney(line.precoUnitario)} / un',
                                      style: Theme.of(context).textTheme.erpCaption.copyWith(color: t.textMuted),
                                    ),
                                    if ((line.service?.tipoServicoClinico ?? '').isNotEmpty)
                                      Text(
                                        line.service!.tipoServicoClinico!,
                                        style: Theme.of(context).textTheme.erpCaption.copyWith(color: t.textSecondary),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    pdvFormatMoney(line.lineTotal),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.erpCardTitle.copyWith(
                                      color: t.brandGreen,
                                    ),
                                  ),
                                  SizedBox(height: s.xs),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox.square(
                                        dimension: t.compactControlHeight,
                                        child: IconButton(
                                          icon: const Icon(Icons.remove_circle_outline_rounded),
                                          color: t.textMuted,
                                          iconSize: t.iconSm,
                                          onPressed: () => onRemove(line),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: s.sm),
                                        child: Text(
                                          '${line.qty}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.erpLabel.copyWith(
                                            color: t.textPrimary,
                                          ),
                                        ),
                                      ),
                                      SizedBox.square(
                                        dimension: t.compactControlHeight,
                                        child: IconButton(
                                          icon: lineBusy
                                              ? PharmaButtonLoader(color: t.brandBlue)
                                              : Icon(
                                                  Icons.add_circle_outline_rounded,
                                                  size: t.iconSm,
                                                ),
                                          color: t.brandBlue,
                                          iconSize: t.iconSm,
                                          onPressed:
                                              (caixaAberto && !isCartBusy && !lineBusy)
                                                  ? () => onAdd(line)
                                                  : null,
                                        ),
                                      ),
                                      SizedBox(width: s.sm),
                                      SizedBox.square(
                                        dimension: t.compactControlHeight,
                                        child: IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded),
                                          color: t.posDanger,
                                          iconSize: t.iconSm,
                                          onPressed: () => onDelete(line),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const Divider(),
            
            // Totals Section
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal', style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textSecondary)),
                    Text(pdvFormatMoney(subtotal), style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.textPrimary)),
                  ],
                ),
                SizedBox(height: s.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Desconto', style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textSecondary)),
                    Text('- ${pdvFormatMoney(discount)}', style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.posDanger)),
                  ],
                ),
                SizedBox(height: s.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(taxLabel, style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textSecondary)),
                    Text(pdvFormatMoney(tax), style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.textPrimary)),
                  ],
                ),
              ],
            ),
            
            SizedBox(height: s.sm),
            Container(
              padding: EdgeInsets.all(s.sm),
              decoration: BoxDecoration(
                color: t.brandGreen.withValues(alpha: 0.1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL',
                    style: Theme.of(
                      context,
                    ).textTheme.erpLabel.copyWith(color: t.brandGreen),
                  ),
                  Text(
                    pdvFormatMoney(total),
                    style: Theme.of(
                      context,
                    ).textTheme.erpAppBarTitle.copyWith(color: t.brandGreen),
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? s.sm : s.md),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancelCart,
                    child: const Text('Cancelar'),
                  ),
                ),
                SizedBox(width: s.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: onCharge,
                    child: Text(
                      compact ? 'Finalizar' : 'Finalizar Venda',
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
