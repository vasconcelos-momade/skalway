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
    if (ref.read(inventarioProvider).hasOpenInventory) return;

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
    final totalLotes = catalogState.resolvedLotesTotal;
    final inventariados = inventoryState.lotesInventariadosCount;
    final naoInventariados =
        inventoryState.lotesNaoInventariadosCount(totalLotes);
    final divergencias = inventoryState.divergenciasCount;
    final inventoryOpen = inventoryState.hasOpenInventory;

    final kpis = [
      EnterpriseStatCard(
        title: 'Total de lotes',
        value: '$totalLotes',
        icon: Icons.inventory_2_outlined,
        accent: StatCardAccent.neutral,
      ),
      EnterpriseStatCard(
        title: 'Lotes inventariados',
        value: '$inventariados',
        icon: Icons.fact_check_outlined,
        accent: StatCardAccent.positive,
      ),
      EnterpriseStatCard(
        title: 'Lotes não inventariados',
        value: '$naoInventariados',
        icon: Icons.pending_actions_outlined,
        accent: StatCardAccent.info,
      ),
      EnterpriseStatCard(
        title: 'Lotes com divergência',
        value: '$divergencias',
        icon: Icons.warning_amber_outlined,
        accent: divergencias > 0
            ? StatCardAccent.warning
            : StatCardAccent.neutral,
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
                ? (inventoryOpen
                    ? FloatingActionButton.extended(
                        onPressed: _openInventariados,
                        icon: const Icon(Icons.list_alt_outlined),
                        label: const Text('Itens Inventariados'),
                      )
                    : FloatingActionButton.extended(
                        onPressed: inventoryState.isCreating
                            ? null
                            : _startInventory,
                        icon: inventoryState.isCreating
                            ? const PharmaButtonLoader()
                            : const Icon(Icons.play_arrow_rounded),
                        label: const Text('Iniciar Inventário'),
                      ))
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
                      if (!inventoryOpen)
                        FilledButton.icon(
                          onPressed: inventoryState.isCreating
                              ? null
                              : _startInventory,
                          icon: inventoryState.isCreating
                              ? const PharmaButtonLoader()
                              : const Icon(Icons.play_arrow_rounded),
                          label: const Text('Iniciar Inventário'),
                        )
                      else
                        FilledButton.icon(
                          onPressed: _openInventariados,
                          icon: const Icon(Icons.list_alt_outlined),
                          label: const Text('Itens Inventariados'),
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
