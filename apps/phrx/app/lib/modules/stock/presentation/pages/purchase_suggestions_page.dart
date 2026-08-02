import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/report_paths.dart';
import '../../../../core/theme/design_metrics.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../shared/widgets/inputs/async_type_ahead_field.dart';
import '../../../../shared/widgets/inputs/enterprise_text_field.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../../../pharmacy/estoque/data/datasources/estoque_remote_datasource.dart';
import '../../../reports/presentation/controllers/report_controller.dart';
import '../../data/datasources/fornecedor_remote_datasource.dart';
import '../../data/models/fornecedor_model.dart';
import '../providers/purchase_suggestions_provider.dart';

String _formatSuggestionQty(num value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}

class PurchaseSuggestionsPage extends ConsumerStatefulWidget {
  const PurchaseSuggestionsPage({super.key});

  @override
  ConsumerState<PurchaseSuggestionsPage> createState() =>
      _PurchaseSuggestionsPageState();
}

class _PurchaseSuggestionsPageState
    extends ConsumerState<PurchaseSuggestionsPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(purchaseSuggestionsProvider).search,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final state = ref.watch(purchaseSuggestionsProvider);
    final controller = ref.read(purchaseSuggestionsProvider.notifier);
    final reportBusy = ref.watch(reportControllerProvider).isSubmitting;
    final totalLabel = state.totalCount ?? state.items.length;

    if (_searchController.text != state.search) {
      _searchController.value = TextEditingValue(
        text: state.search,
        selection: TextSelection.collapsed(offset: state.search.length),
      );
    }

    final kpiCards = [
      EnterpriseStatCard(
        title: 'Produtos sugeridos',
        value: '${state.dashboard.produtosAbaixoMinimo}',
        icon: Icons.inventory_2_outlined,
      ),
      EnterpriseStatCard(
        title: 'Sem stock',
        value: '${state.dashboard.produtosSemStock}',
        icon: Icons.error_outline,
        accent: StatCardAccent.danger,
      ),
      EnterpriseStatCard(
        title: 'Qtd. total sugerida',
        value: '${state.dashboard.quantidadeTotalSugerida}',
        icon: Icons.functions_outlined,
      ),
      EnterpriseStatCard(
        title: 'Fornecedores',
        value: '${state.dashboard.fornecedoresEnvolvidos}',
        icon: Icons.local_shipping_outlined,
      ),
      EnterpriseStatCard(
        title: 'Valor estimado',
        value: '${state.dashboard.valorEstimadoCompra} MZN',
        icon: Icons.payments_outlined,
      ),
    ];

    final exportMenu = PopupMenuButton<String>(
      tooltip: 'Exportar',
      enabled: !state.isLoading && !reportBusy,
      icon: const Icon(Icons.file_download_outlined),
      onSelected: (format) => _exportReport(ref, format, state),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'print', child: Text('Imprimir')),
        const PopupMenuItem(value: 'pdf', child: Text('Exportar PDF')),
        const PopupMenuItem(value: 'excel', child: Text('Exportar Excel')),
      ],
    );

    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = !constraints.isTabletOrWider;

        return Scaffold(
          backgroundColor: t.bgPrimary,
          body: EnterpriseModuleHub(
            title: 'Sugestão de Compra',
            subtitle:
                'Lista consolidada de produtos para reposição — automáticos e manuais.',
            mobileKpisHorizontalScroll: true,
            kpis: isMobile ? null : kpiCards,
            filters: isMobile
                ? null
                : EnterpriseDesktopListToolbar(
                    searchController: _searchController,
                    searchHint: 'Pesquisar produto...',
                    isLoading: state.isLoading,
                    onSearchSubmitted: controller.setSearch,
                    hasFilters: false,
                    trailingActions: [
                      TextButton.icon(
                        onPressed: state.isLoading ||
                                state.isMutating ||
                                state.items.isEmpty
                            ? null
                            : () => _confirmClear(context, controller),
                        icon: const Icon(Icons.delete_sweep_outlined),
                        label: const Text('Limpar lista'),
                      ),
                      Text(
                        '$totalLabel sugestão(ões)',
                        style: Theme.of(context)
                            .textTheme
                            .erpBodySecondary
                            .copyWith(color: t.textMuted),
                      ),
                      exportMenu,
                    ],
                    filterWidgets: const [],
                  ),
            actions: isMobile
                ? null
                : [
                    OutlinedButton.icon(
                      onPressed: state.isLoading || state.isMutating
                          ? null
                          : () => _showAddProductDialog(context, ref),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Adicionar Produto'),
                    ),
                  ],
            child: EnterpriseAdaptiveListBody(
              isMobile: isMobile,
              isLoading: state.isLoading && state.items.isEmpty,
              errorText: state.errorMessage != null && state.items.isEmpty
                  ? state.errorMessage
                  : null,
              desktopToolbar: null,
              desktopContent: _buildDesktopContent(context, state, controller),
              desktopPagination: (state.totalCount ?? 0) > 0
                  ? EnterprisePagination(
                      page: state.page,
                      pageSize: state.pageSize,
                      totalCount: state.totalCount,
                      hasMore: state.hasMore,
                      itemsOnPage: state.items.length,
                      itemLabel: 'sugestões',
                      onPageChanged: controller.goToPage,
                      onPageSizeChanged: controller.setPageSize,
                      isBusy: state.isLoading,
                    )
                  : null,
              mobileList: EnterpriseMobileScrollList(
                kpis: kpiCards,
                stickyHeader: EnterpriseMobileToolbar(
                  searchController: _searchController,
                  searchHint: 'Pesquisar produto...',
                  enabled: !state.isLoading,
                  isLoading: state.isLoading,
                  hasFilters: false,
                  showFiltersButton: false,
                  showRefreshButton: false,
                  onSearchSubmitted: controller.setSearch,
                  onOpenFilters: () {},
                  onRefresh: controller.load,
                  reportAction: exportMenu,
                ),
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  return _PurchaseSuggestionMobileCard(
                    item: item,
                    isMutating: state.isMutating,
                    onEdit: () =>
                        _showAddProductDialog(context, ref, item: item),
                    onRemove: () =>
                        controller.removeSuggestion(item.produtoId),
                  );
                },
                hasMore: state.hasMore,
                isLoading: state.isLoading,
                onLoadMore: () => controller.goToPage(state.page + 1),
                emptyMessage: 'Nenhuma sugestão de compra registada',
                totalCount: state.totalCount,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopContent(
    BuildContext context,
    PurchaseSuggestionsState state,
    PurchaseSuggestionsController controller,
  ) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.errorMessage != null)
          Padding(
            padding: EdgeInsets.only(bottom: s.sm),
            child: Text(
              state.errorMessage!,
              style: Theme.of(context)
                  .textTheme
                  .erpBodySecondary
                  .copyWith(color: t.posDanger),
            ),
          ),
        if (state.successMessage != null)
          Padding(
            padding: EdgeInsets.only(bottom: s.sm),
            child: Text(
              state.successMessage!,
              style: Theme.of(context)
                  .textTheme
                  .erpBodySecondary
                  .copyWith(color: t.posSuccess),
            ),
          ),
        Expanded(
          child: state.items.isEmpty && !state.isLoading
              ? Center(
                  child: Text(
                    'Nenhuma sugestão de compra registada',
                    style: Theme.of(context)
                        .textTheme
                        .erpBodySecondary
                        .copyWith(color: t.textMuted),
                  ),
                )
              : EnterpriseDataTable(
                  columns: const [
                    DataColumn(label: Text('PRODUTO')),
                    DataColumn(label: Text('ORIGEM')),
                    DataColumn(label: Text('FORNECEDOR')),
                    DataColumn(label: Text('ESTOQUE ATUAL')),
                    DataColumn(label: Text('EST. MÍNIMO')),
                    DataColumn(label: Text('CONSUMO/DIA')),
                    DataColumn(label: Text('QTD. SUGERIDA')),
                    DataColumn(label: Text('OBSERVAÇÃO')),
                    DataColumn(label: Text('')),
                  ],
                  rowCount: state.items.length,
                  rowBuilder: (context, index) {
                    final item = state.items[index];
                    return DataRow(
                      cells: [
                        DataCell(Text(item.produtoNome)),
                        DataCell(Text(item.origemLabel)),
                        DataCell(Text(item.fornecedorNome)),
                        DataCell(Text(_formatSuggestionQty(item.estoqueAtual))),
                        DataCell(Text(_formatSuggestionQty(item.estoqueMinimo))),
                        DataCell(Text(_formatSuggestionQty(item.consumoMedioDiario))),
                        DataCell(Text(_formatSuggestionQty(item.quantidadeSugerida))),
                        DataCell(Text(item.observacao ?? '—')),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                onPressed: state.isMutating
                                    ? null
                                    : () => _showAddProductDialog(
                                          context,
                                          ref,
                                          item: item,
                                        ),
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: t.iconSm,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Remover',
                                onPressed: state.isMutating
                                    ? null
                                    : () => controller
                                        .removeSuggestion(item.produtoId),
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: t.iconSm,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  static Map<String, dynamic> _reportParams(PurchaseSuggestionsState state) {
    return <String, dynamic>{
      if (state.search.trim().isNotEmpty) 'q': state.search.trim(),
    };
  }

  static Future<void> _exportReport(
    WidgetRef ref,
    String format,
    PurchaseSuggestionsState state,
  ) async {
    final controller = ref.read(reportControllerProvider.notifier);
    final params = _reportParams(state);
    switch (format) {
      case 'print':
        await controller.printPdf(
          path: ReportPaths.stockPurchaseSuggestions,
          queryParameters: params,
        );
      case 'pdf':
        await controller.downloadPdf(
          path: ReportPaths.stockPurchaseSuggestions,
          queryParameters: params,
        );
      case 'excel':
        await controller.exportExcel(
          path: ReportPaths.stockPurchaseSuggestions,
          queryParameters: params,
        );
    }
  }

  static Future<void> _confirmClear(
    BuildContext context,
    PurchaseSuggestionsController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar sugestões'),
        content: const Text(
          'Remover todas as sugestões da lista? Esta acção não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.clearSuggestions();
    }
  }

  static Future<void> _showAddProductDialog(
    BuildContext context,
    WidgetRef ref, {
    PurchaseSuggestionItem? item,
  }) async {
    await AdaptiveNavigator.openForm<void>(
      context: context,
      title: Text(item == null ? 'Adicionar produto' : 'Editar sugestão'),
      contentBuilder: (formContext) => _AddProductDialogBody(
        parentRef: ref,
        item: item,
      ),
    );
  }
}

class _PurchaseSuggestionMobileCard extends StatelessWidget {
  const _PurchaseSuggestionMobileCard({
    required this.item,
    required this.isMutating,
    required this.onEdit,
    required this.onRemove,
  });

  final PurchaseSuggestionItem item;
  final bool isMutating;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;

    return EnterpriseListCard(
      title: item.produtoNome,
      subtitle: item.fornecedorNome,
      leading: Icons.shopping_cart_outlined,
      isBusy: isMutating,
      metadata: [
        EnterpriseListCardMeta(
          label:
              'Sugerida: ${_formatSuggestionQty(item.quantidadeSugerida)}',
        ),
        EnterpriseListCardMeta(
          label: 'Stock: ${_formatSuggestionQty(item.estoqueAtual)}',
        ),
        EnterpriseListCardMeta(
          label: 'Origem: ${item.origemLabel}',
        ),
      ],
      actions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Editar',
            onPressed: isMutating ? null : onEdit,
            icon: Icon(Icons.edit_outlined, size: t.iconSm),
          ),
          IconButton(
            tooltip: 'Remover',
            onPressed: isMutating ? null : onRemove,
            icon: Icon(Icons.close_rounded, size: t.iconSm),
          ),
        ],
      ),
    );
  }
}

class _AddProductDialogBody extends ConsumerStatefulWidget {
  const _AddProductDialogBody({required this.parentRef, this.item});

  final WidgetRef parentRef;
  final PurchaseSuggestionItem? item;

  @override
  ConsumerState<_AddProductDialogBody> createState() =>
      _AddProductDialogBodyState();
}

class _AddProductDialogBodyState extends ConsumerState<_AddProductDialogBody> {
  late final TextEditingController _produtoController;
  late final TextEditingController _fornecedorController;
  late final TextEditingController _qtyController;
  late final TextEditingController _obsController;

  ProdutoSearchResult? _selectedProduto;
  FornecedorDetalheModel? _selectedFornecedor;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _produtoController =
        TextEditingController(text: widget.item?.produtoNome ?? '');
    _fornecedorController =
        TextEditingController(text: widget.item?.fornecedorNome ?? '');
    _qtyController = TextEditingController(
      text: widget.item != null
          ? widget.item!.quantidadeSugerida.toString()
          : '1',
    );
    _obsController =
        TextEditingController(text: widget.item?.observacao ?? '');

    if (widget.item != null) {
      _selectedProduto = ProdutoSearchResult(
        id: widget.item!.produtoId,
        nomeComercial: widget.item!.produtoNome,
      );
      if (widget.item!.fornecedorId != null) {
        _selectedFornecedor = FornecedorDetalheModel(
          id: widget.item!.fornecedorId!,
          nome: widget.item!.fornecedorNome,
          ativo: true,
        );
      }
    }
  }

  @override
  void dispose() {
    _produtoController.dispose();
    _fornecedorController.dispose();
    _qtyController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final produto = _selectedProduto;
    final fornecedor = _selectedFornecedor;
    final qty = num.tryParse(_qtyController.text.replaceAll(',', '.'));
    if (produto == null || fornecedor == null || qty == null || qty <= 0) {
      return;
    }

    setState(() => _isSubmitting = true);
    final controller =
        widget.parentRef.read(purchaseSuggestionsProvider.notifier);
    await controller.addManualSuggestion(
      produtoId: produto.id,
      supplierId: fornecedor.id,
      quantidadeSugerida: qty,
      observacao: _obsController.text.trim().isEmpty
          ? null
          : _obsController.text.trim(),
    );

    if (!mounted) return;
    final state = widget.parentRef.read(purchaseSuggestionsProvider);
    if (state.errorMessage == null) {
      AdaptiveNavigator.complete(context);
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final t = context.pharmaTokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AsyncTypeAheadField<ProdutoSearchResult>(
          controller: _produtoController,
          labelText: 'Produto',
          hintText: 'Nome comercial, dosagem ou forma',
          suggestionsCallback: (query) => ref
              .read(estoqueRemoteDataSourceProvider)
              .searchProdutos(query: query),
          itemLabel: (item) => item.nomeComercial,
          itemSubtitle: (item) => item.detalhesLabel,
          onSelected: (item) {
            setState(() {
              _selectedProduto = item;
              _produtoController.text = item.displayLabel;
            });
          },
        ),
        SizedBox(height: s.md),
        AsyncTypeAheadField<FornecedorDetalheModel>(
          controller: _fornecedorController,
          labelText: 'Fornecedor',
          hintText: 'Digite para pesquisar o fornecedor',
          suggestionsCallback: (query) async {
            final result = await ref
                .read(fornecedorRemoteDataSourceProvider)
                .search(query: query, pageSize: 10);
            return result.items;
          },
          itemLabel: (fornecedor) => fornecedor.nome,
          itemSubtitle: (fornecedor) {
            final parts = <String>[
              if (fornecedor.nuit != null &&
                  fornecedor.nuit!.trim().isNotEmpty)
                'NUIT ${fornecedor.nuit}',
              if (fornecedor.telefone != null &&
                  fornecedor.telefone!.trim().isNotEmpty)
                fornecedor.telefone!.trim(),
            ];
            return parts.join(' · ');
          },
          onSelected: (fornecedor) {
            setState(() {
              _selectedFornecedor = fornecedor;
              _fornecedorController.text = fornecedor.nome;
            });
          },
        ),
        SizedBox(height: s.md),
        EnterpriseTextField(
          controller: _qtyController,
          labelText: 'Quantidade sugerida',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        SizedBox(height: s.md),
        EnterpriseTextField(
          controller: _obsController,
          labelText: 'Observação',
          hintText: 'Opcional',
          maxLines: 2,
        ),
        SizedBox(height: s.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () => AdaptiveNavigator.complete(context),
              child: const Text('Cancelar'),
            ),
            SizedBox(width: s.sm),
            FilledButton(
              onPressed: _selectedProduto == null ||
                      _selectedFornecedor == null ||
                      _isSubmitting
                  ? null
                  : _submit,
              child: _isSubmitting
                  ? SizedBox(
                      width: t.iconSm,
                      height: t.iconSm,
                      child: CircularProgressIndicator(
                        strokeWidth: DesignMetrics.buttonLoaderStrokeWidth,
                      ),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ],
    );
  }
}
