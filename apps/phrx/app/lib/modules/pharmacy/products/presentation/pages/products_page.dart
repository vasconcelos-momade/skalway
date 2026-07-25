import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers/auth_session_notifier.dart';
import '../../../../../core/constants/report_paths.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/responsive/responsive_builder.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/dialogs/enterprise_overlay_tokens.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../domain/entities/product.dart';
import '../providers/product_provider.dart';
import '../widgets/produto_form_dialog.dart';
import '../widgets/produto_filters_bottom_sheet.dart';
import '../widgets/produto_list.dart';
import '../widgets/produto_table.dart';
import '../widgets/produto_pagination.dart';
import '../widgets/produto_empty_state.dart';
import '../widgets/produto_loading.dart';
import '../widgets/produto_toolbar.dart';
import '../../../presentation/widgets/pharmacy_report_exports.dart';

/// Catálogo master de produtos refatorado para mobile, tablet e desktop.
class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _accumulatedItems = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final t = context.pharmaTokens;
    final state = ref.watch(masterProductListProvider);
    final controller = ref.read(masterProductListProvider.notifier);
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    final authReady = ref.watch(
      authSessionProvider.select(
        (session) => !session.isBootstrapping && session.hasTenantContext,
      ),
    );
    final categories = authReady
        ? (categoriesAsync.asData?.value ?? const <Category>[])
        : const <Category>[];

    if (_searchController.text != state.query) {
      _searchController.value = TextEditingValue(
        text: state.query,
        selection: TextSelection.collapsed(offset: state.query.length),
      );
    }

    ref.listen(masterProductListProvider, (prev, next) {
      if (prev?.page != next.page ||
          prev?.query != next.query ||
          prev?.categoriaId != next.categoriaId ||
          prev?.ativoFilter != next.ativoFilter ||
          prev?.sortBy != next.sortBy ||
          prev?.sortOrder != next.sortOrder) {
        if (next.page == 1) {
          _accumulatedItems = List.of(next.items);
        } else {
          final newItems = next.items
              .where((e) => !_accumulatedItems.any((a) => a.id == e.id))
              .toList();
          _accumulatedItems.addAll(newItems);
        }
      } else if (prev?.items != next.items && next.page == 1) {
        _accumulatedItems = List.of(next.items);
      }
    });

    final reportQuery = <String, dynamic>{
      if (state.query.isNotEmpty) 'q': state.query,
      if (state.categoriaId != null) 'categoriaId': state.categoriaId,
      if (state.fornecedorId != null) 'fornecedorId': state.fornecedorId,
      if (state.tipoDispensacao != null) 'tipoDispensacao': state.tipoDispensacao,
    };

    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.isDesktopOrWider;
        final isMobile = !constraints.isTabletOrWider;

        return Scaffold(
          backgroundColor: t.bgPrimary,
          floatingActionButton: isMobile
              ? FloatingActionButton(
                  onPressed: state.isLoading ? null : () => _openCreateDialog(context, ref),
                  child: const Icon(Icons.add),
                )
              : null,
          body: EnterpriseModuleHub(
            title: 'Produtos',
            subtitle: 'Catálogo master com stock, lotes, validades e regras ANARME.',
            filters: isMobile
                ? null
                : ProdutoToolbar(
                    searchController: _searchController,
                    state: state,
                    controller: controller,
                    categories: categories,
                    onSearchChanged: controller.onSearchChanged,
                    onOpenMobileFilters: () =>
                        _openFilters(context, controller, state, categories),
                  ),
            actions: isMobile
                ? null
                : [
                    OutlinedButton.icon(
                      onPressed:
                          state.isLoading ? null : () => controller.refreshCurrentPage(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Atualizar'),
                    ),
                    ...pharmacyReportActions(
                      ref: ref,
                      enabled: !state.isLoading,
                      path: ReportPaths.pharmacyProductsCatalog,
                      queryParameters: reportQuery,
                      isIconButton: false,
                    ),
                    FilledButton.icon(
                      onPressed: state.isLoading ? null : () => _openCreateDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Novo produto'),
                    ),
                  ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isMobile) ...[
                  ProdutoMobileToolbar(
                    searchController: _searchController,
                    state: state,
                    controller: controller,
                    onSearchChanged: controller.onSearchChanged,
                    onOpenFilters: () =>
                        _openFilters(context, controller, state, categories),
                    reportAction: pharmacyReportActions(
                      ref: ref,
                      enabled: !state.isLoading,
                      path: ReportPaths.pharmacyProductsCatalog,
                      queryParameters: reportQuery,
                      expandChild: true,
                      buttonLabel: 'Exportar..',
                    ).single,
                  ),
                  SizedBox(height: s.sm),
                ],
                if (pharmacyReportError(ref) != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: s.sm),
                    child: pharmacyReportError(ref),
                  ),
                if (state.errorMessage != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: s.sm),
                    child: Text(
                      state.errorMessage!,
                      style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                            color: t.posDanger,
                          ),
                    ),
                  ),
                Expanded(
                  child: !state.isInitialized && state.isLoading
                      ? ProdutoLoading(isDesktop: isDesktop)
                      : (isDesktop ? state.items.isEmpty : _accumulatedItems.isEmpty)
                          ? const ProdutoEmptyState()
                          : isDesktop
                              ? ProdutoTable(
                                  items: state.items,
                                  sortBy: state.sortBy,
                                  sortOrder: state.sortOrder,
                                  onSort: controller.setSort,
                                  onAction: (p, action) =>
                                      _handleAction(context, ref, p, action),
                                )
                              : ProdutoList(
                                  items: _accumulatedItems,
                                  hasMore: state.hasMore,
                                  isLoading: state.isLoading,
                                  onLoadMore: () => controller.goToPage(state.page + 1),
                                  onItemTap: (_) {},
                                  onItemAction: (p, action) =>
                                      _handleAction(context, ref, p, action),
                                ),
                ),
                if (isDesktop && state.isInitialized && state.totalCount != null)
                  ProdutoPagination(
                    page: state.page,
                    pageSize: state.pageSize,
                    totalCount: state.totalCount!,
                    onPageChanged: controller.goToPage,
                    onPageSizeChanged: controller.setPageSize,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFilters(
    BuildContext context,
    MasterProductListController controller,
    MasterProductListState state,
    List<Category> categories,
  ) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      barrierColor: enterpriseOverlayScrim(context),
      backgroundColor: scheme.surface.withValues(alpha: 0),
      builder: (_) => ProdutoFiltersBottomSheet(
        initialAtivo: state.ativoFilter,
        initialCategoriaId: state.categoriaId,
        categories: categories,
        onApply: (ativo, categoriaId) {
          controller.setAtivoFilter(ativo);
          controller.setCategoriaIdFilter(categoriaId);
        },
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, Product product, String action) {
    switch (action) {
      case 'editar':
        _openEditDialog(context, ref, product);
        break;
      case 'excluir':
        _confirmDeleteProduct(context, ref, product);
        break;
    }
  }

  Future<void> _openCreateDialog(BuildContext context, WidgetRef ref) async {
    final result = await showProdutoFormDialog(context);
    if (result == null || !context.mounted) return;

    try {
      await ref.read(masterProductListProvider.notifier).createProduct(result.toPayload());
      if (context.mounted) {
        PharmaFeedback.success(context, 'Produto criado com sucesso');
      }
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    } catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.toString());
    }
  }

  Future<void> _openEditDialog(BuildContext context, WidgetRef ref, Product product) async {
    final result = await showProdutoFormDialog(context, product: product);
    if (result == null || !context.mounted) return;

    try {
      await ref
          .read(masterProductListProvider.notifier)
          .updateProduct(product.id, result.toPayload());
      if (context.mounted) {
        PharmaFeedback.success(context, 'Produto actualizado com sucesso');
      }
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    } catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.toString());
    }
  }

  Future<void> _confirmDeleteProduct(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final confirmed = await PharmaFeedback.confirm(
      context: context,
      title: 'Confirmar exclusão',
      message:
          'Deseja excluir o produto «${product.nomeComercial}»?\n\n'
          'A operação seguirá o padrão actual do sistema.',
      confirmText: 'Excluir',
      cancelText: 'Cancelar',
      destructive: true,
    );
    if (!context.mounted || confirmed != true) return;

    try {
      await ref.read(masterProductListProvider.notifier).deleteProduct(product.id);
      if (context.mounted) {
        PharmaFeedback.success(context, 'Produto excluído com sucesso');
      }
    } on ApiFailure catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.message);
    } catch (e) {
      if (context.mounted) PharmaFeedback.error(context, e.toString());
    }
  }
}
