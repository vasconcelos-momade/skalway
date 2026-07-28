import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/auth_session_notifier.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/refresh/page_refresh.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../../../../shared/widgets/buttons/pharma_button_loader.dart';
import '../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../pharmacy/categories/domain/entities/category.dart';
import '../../../pharmacy/categories/presentation/providers/category_provider.dart';
import '../../domain/entities/inventario.dart';
import '../providers/inventario_provider.dart';
import '../providers/inventory_catalog_provider.dart';
import '../widgets/inventory_count_sheet.dart';
import '../widgets/inventory_items_sheet.dart';
import '../widgets/inventory_products_tab.dart';

/// Página operacional de Inventário — padrão Enterprise (hub + tabela + side sheets).
class InventoryHubPage extends ConsumerStatefulWidget {
  const InventoryHubPage({super.key});

  @override
  ConsumerState<InventoryHubPage> createState() => _InventoryHubPageState();
}

class _InventoryHubPageState extends ConsumerState<InventoryHubPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(inventoryCatalogProvider).query;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshPage() async {
    await Future.wait([
      ref.read(inventarioProvider.notifier).refreshLists(),
      ref.read(inventoryCatalogProvider.notifier).refreshCurrentPage(),
    ]);
  }

  Future<void> _startInventory() async {
    final result = await showNovoInventarioDialog(context);
    if (!mounted || result == null) return;

    await ref.read(inventarioProvider.notifier).startInventory(
          observacao: result.observacao,
        );
  }

  Future<void> _inventariar(InventarioProdutoApto produto) async {
    final state = ref.read(inventarioProvider);
    if (!state.canInventariar) {
      PharmaFeedback.error(
        context,
        'Inicie um inventário antes de inventariar produtos.',
      );
      return;
    }

    await showInventariarProdutoSheet(
      context,
      ref: ref,
      produto: produto,
    );
  }

  Future<void> _openInventariados() async {
    if (!ref.read(inventarioProvider).hasOpenInventory) return;
    await showInventariadosSheet(context);
  }

  Future<void> _concluirInventario() async {
    final state = ref.read(inventarioProvider);
    if (!state.canReconcile) return;

    final confirmed = await PharmaFeedback.confirm(
      context: context,
      title: 'Concluir Inventário',
      message:
          'Serão gerados movimentos AJUSTE para cada divergência e o inventário será marcado como concluído. Continuar?',
      confirmText: 'Concluir',
      cancelText: 'Cancelar',
    );

    if (!mounted || confirmed != true) return;
    await ref.read(inventarioProvider.notifier).reconcileActiveInventory();
    await ref.read(inventoryCatalogProvider.notifier).refreshCurrentPage();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final inventoryState = ref.watch(inventarioProvider);
    final catalogState = ref.watch(inventoryCatalogProvider);
    final authReady = ref.watch(
      authSessionProvider.select(
        (session) => !session.isBootstrapping && session.hasTenantContext,
      ),
    );
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    final categories = authReady
        ? (categoriesAsync.asData?.value ?? const <Category>[])
        : const <Category>[];

    ref.listen<InventarioState>(inventarioProvider, (previous, next) {
      if (!mounted) return;
      if (previous?.errorMessage != next.errorMessage &&
          next.errorMessage != null) {
        PharmaFeedback.error(context, next.errorMessage!);
      }
      if (previous?.successMessage != next.successMessage &&
          next.successMessage != null) {
        PharmaFeedback.success(context, next.successMessage!);
      }
    });

    final active = inventoryState.activeInventory;
    final kpis = [
      EnterpriseStatCard(
        title: 'Produtos',
        value: '${catalogState.resolvedTotalCount ?? catalogState.items.length}',
        icon: Icons.medication_outlined,
      ),
      EnterpriseStatCard(
        title: 'Stock Total',
        value: formatInventoryQuantity(catalogState.stockTotalPage),
        icon: Icons.inventory_2_outlined,
      ),
      EnterpriseStatCard(
        title: 'Produtos Inventariados',
        value: '${inventoryState.produtosInventariadosCount}',
        icon: Icons.fact_check_outlined,
      ),
      EnterpriseStatCard(
        title: 'Divergências',
        value: '${inventoryState.divergenciasCount}',
        icon: Icons.warning_amber_outlined,
      ),
    ];

    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = !constraints.isTabletOrWider;

        return PageRefreshBinder(
          onRefresh: _refreshPage,
          child: Scaffold(
            backgroundColor: t.bgPrimary,
            floatingActionButton: isMobile
                ? FloatingActionButton.extended(
                    onPressed:
                        inventoryState.isCreating ? null : _startInventory,
                    icon: inventoryState.isCreating
                        ? const PharmaButtonLoader()
                        : const Icon(Icons.play_arrow_rounded),
                    label: const Text('Iniciar Inventário'),
                  )
                : null,
            body: EnterpriseModuleHub(
              title: 'Inventário',
              subtitle:
                  'Controle e conferência física do estoque por lote.',
              tag: active == null
                  ? null
                  : '${active.codigo} · ${active.status.label}',
              mobileKpisHorizontalScroll: true,
              kpis: kpis,
              actions: isMobile
                  ? null
                  : [
                      FilledButton.icon(
                        onPressed: inventoryState.isCreating
                            ? null
                            : _startInventory,
                        icon: inventoryState.isCreating
                            ? const PharmaButtonLoader()
                            : const Icon(Icons.play_arrow_rounded),
                        label: const Text('Iniciar Inventário'),
                      ),
                      OutlinedButton.icon(
                        onPressed: inventoryState.hasOpenInventory
                            ? _openInventariados
                            : null,
                        icon: const Icon(Icons.list_alt_outlined),
                        label: const Text('Itens Inventariados'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: inventoryState.canReconcile
                            ? _concluirInventario
                            : null,
                        icon: inventoryState.isReconciling
                            ? const PharmaButtonLoader()
                            : const Icon(Icons.check_circle_outline),
                        label: const Text('Concluir Inventário'),
                      ),
                    ],
              child: InventoryProductsTab(
                searchController: _searchController,
                canInventariar: inventoryState.canInventariar &&
                    !inventoryState.isRecordingCount,
                categories: categories,
                onInventariar: _inventariar,
              ),
            ),
          ),
        );
      },
    );
  }
}
