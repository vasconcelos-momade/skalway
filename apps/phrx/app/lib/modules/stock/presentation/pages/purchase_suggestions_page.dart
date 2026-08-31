import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/session_access_notifier.dart';
import '../../../../core/constants/report_paths.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../shared/responsive/pharma_screen_layout.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../shared/widgets/dialogs/enterprise_overlay_chrome.dart';
import '../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../shared/widgets/inputs/async_type_ahead_field.dart';
import '../../../../shared/widgets/inputs/enterprise_date_field.dart';
import '../../../../shared/widgets/inputs/enterprise_text_field.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/menus/enterprise_actions_menu_button.dart';
import '../../../../shared/widgets/menus/enterprise_dropdown_menu.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../../../../shared/widgets/tables/enterprise_table_cells.dart';
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

String _formatSuggestionInteger(num value) {
  return value.round().toString();
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
    ref.watch(sessionAccessProvider);

    ref.listen<PurchaseSuggestionsState>(purchaseSuggestionsProvider, (prev, next) {
      if (!context.mounted) return;
      if (next.successMessage != null &&
          next.successMessage != prev?.successMessage &&
          next.items.isNotEmpty) {
        PharmaFeedback.success(context, next.successMessage!);
      }
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage &&
          next.items.isNotEmpty) {
        PharmaFeedback.error(context, next.errorMessage!);
      }
    });

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
        final s = context.spacing;

        return Scaffold(
          backgroundColor: t.bgPrimary,
          floatingActionButton: isMobile
              ? FloatingActionButton(
                  onPressed: state.isLoading || state.isMutating
                      ? null
                      : () => _showSuggestionDialog(context, ref),
                  child: const Icon(Icons.add_rounded),
                )
              : null,
          body: EnterpriseModuleHub(
            title: 'Sugestão de Compra',
            subtitle:
                'Lista consolidada de produtos para reposição — automáticos e manuais.',
            mobileKpisHorizontalScroll: true,
            kpis: isMobile ? null : kpiCards,
            filters: _buildPeriodFilters(
              context,
              state,
              controller,
              isMobile: isMobile,
            ),
            actions: [
              if (!isMobile)
                OutlinedButton.icon(
                  onPressed: state.isLoading || state.isMutating
                      ? null
                      : () => _showSuggestionDialog(context, ref),
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
              desktopToolbar: EnterpriseDesktopListToolbar(
                searchController: _searchController,
                searchHint: 'Pesquisar produto...',
                isLoading: state.isLoading,
                onSearchSubmitted: controller.setSearch,
                hasFilters: false,
                trailingActions: [exportMenu],
                filterWidgets: const [],
              ),
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
                stickyHeader: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EnterpriseMobileToolbar(
                      searchController: _searchController,
                      searchHint: 'Pesquisar produto...',
                      enabled: !state.isLoading && !state.isRefreshing,
                      isLoading: state.isLoading || state.isRefreshing,
                      hasFilters: false,
                      showFiltersButton: false,
                      showRefreshButton: false,
                      onSearchSubmitted: controller.setSearch,
                      onOpenFilters: () {},
                      onRefresh: controller.load,
                      reportAction: exportMenu,
                    ),
                  ],
                ),
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  return _PurchaseSuggestionMobileCard(
                    item: item,
                    isMutating: state.isMutating,
                    onEdit: () =>
                        _showSuggestionDialog(context, ref, item: item),
                    onRemove: () => _confirmRemove(
                      context,
                      controller,
                      item.produtoId,
                    ),
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

  Widget _buildPeriodFilters(
    BuildContext context,
    PurchaseSuggestionsState state,
    PurchaseSuggestionsController controller, {
    required bool isMobile,
  }) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final busy = state.isLoading || state.isMutating || state.isRefreshing;

    final dataInicialField = EnterpriseDateField(
      labelText: 'Data Inicial',
      value: state.dataInicial,
      lastDate: state.dataFinal,
      enabled: !busy,
      onChanged: (picked) {
        if (picked != null) {
          controller.setDataInicial(picked);
        }
      },
    );

    final dataFinalField = EnterpriseDateField(
      labelText: 'Data Final',
      value: state.dataFinal,
      firstDate: state.dataInicial,
      enabled: !busy,
      onChanged: (picked) {
        if (picked != null) {
          controller.setDataFinal(picked);
        }
      },
    );

    final refreshButton = OutlinedButton.icon(
      onPressed: busy ? null : () => controller.refreshList(),
      icon: state.isRefreshing
          ? SizedBox(
              width: t.iconSm,
              height: t.iconSm,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: t.textSecondary,
              ),
            )
          : const Icon(Icons.refresh_rounded),
      label: const Text(
        'Atualizar Lista',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    if (isMobile) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: dataInicialField),
          SizedBox(width: s.sm),
          Expanded(child: dataFinalField),
          SizedBox(width: s.sm),
          Expanded(child: refreshButton),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(child: dataInicialField),
        SizedBox(width: s.sm),
        Flexible(child: dataFinalField),
        SizedBox(width: s.sm),
        refreshButton,
      ],
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
          child: EnterpriseDataTable(
                  status: state.isLoading && state.items.isEmpty
                      ? EnterpriseTableStatus.loading
                      : state.items.isEmpty
                          ? EnterpriseTableStatus.empty
                          : EnterpriseTableStatus.data,
                  emptyTitle: 'Nenhum resultado encontrado',
                  emptyMessage: 'Nenhum resultado encontrado',
                  columns: [
                    enterpriseDataColumn(context, '#'),
                    enterpriseDataColumn(context, 'Produto'),
                    enterpriseDataColumn(context, 'Stock atual'),
                    enterpriseDataColumn(context, 'Stock mínimo'),
                    enterpriseDataColumn(context, 'Saídas'),
                    enterpriseDataColumn(context, 'QTD sugerida'),
                    enterpriseDataColumn(context, 'QTD. aprovada'),
                    enterpriseDataColumn(context, 'Ações'),
                  ],
                  rowCount: state.items.length,
                  rowBuilder: (context, index) {
                    final item = state.items[index];
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            '${index + 1}',
                            softWrap: false,
                            maxLines: 1,
                          ),
                        ),
                        DataCell(Text(item.produtoDisplayLabel)),
                        DataCell(Text(_formatSuggestionQty(item.estoqueAtual))),
                        DataCell(Text(_formatSuggestionQty(item.estoqueMinimo))),
                        DataCell(
                          Text(_formatSuggestionInteger(item.totalSaidasPeriodo)),
                        ),
                        DataCell(
                          Text(_formatSuggestionInteger(item.quantidadeSugerida)),
                        ),
                        DataCell(
                          Text(_formatSuggestionInteger(item.quantidadeAprovada)),
                        ),
                        DataCell(
                          EnterpriseActionsMenuButton<String>(
                            compact: true,
                            enabled: !state.isMutating,
                            items: const [
                              EnterpriseDropdownItem(
                                value: 'editar',
                                label: 'Editar',
                                icon: Icons.edit_outlined,
                              ),
                              EnterpriseDropdownItem(
                                value: 'remover',
                                label: 'Remover',
                                icon: Icons.delete_outline,
                                destructive: true,
                              ),
                            ],
                            onSelected: (action) {
                              if (action == 'editar') {
                                _showSuggestionDialog(
                                  context,
                                  ref,
                                  item: item,
                                );
                              } else if (action == 'remover') {
                                _confirmRemove(
                                  context,
                                  controller,
                                  item.produtoId,
                                );
                              }
                            },
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
      'dataInicio': formatPurchaseSuggestionApiDate(state.dataInicial),
      'dataFim': formatPurchaseSuggestionApiDate(state.dataFinal),
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

  static Future<void> _confirmRemove(
    BuildContext context,
    PurchaseSuggestionsController controller,
    String produtoId,
  ) async {
    final confirmed = await PharmaFeedback.confirm(
      context: context,
      title: 'Remover item',
      message:
          'Tem certeza de que pretende remover este item da sugestão de compras?',
      confirmText: 'Remover',
      destructive: true,
    );
    if (confirmed == true) {
      await controller.removeSuggestion(produtoId);
    }
  }

  static Future<void> _showSuggestionDialog(
    BuildContext context,
    WidgetRef ref, {
    PurchaseSuggestionItem? item,
  }) async {
    await AdaptiveNavigator.openEmbeddedForm<void>(
      context: context,
      title: Text(item == null ? 'Adicionar produto' : 'Editar sugestão'),
      mobileWrapInScrollView: false,
      formBuilder: (formContext, {required embedded}) => _SuggestionFormDialog(
        parentRef: ref,
        item: item,
        embedded: embedded,
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
    return EnterpriseListCard(
      title: item.produtoDisplayLabel,
      subtitle: item.fornecedorNome,
      leading: Icons.shopping_cart_outlined,
      isBusy: isMutating,
      metadata: [
        EnterpriseListCardMeta(
          label:
              'Sugerida: ${_formatSuggestionInteger(item.quantidadeSugerida)}',
        ),
        EnterpriseListCardMeta(
          label:
              'Aprovada: ${_formatSuggestionInteger(item.quantidadeAprovada)}',
        ),
        EnterpriseListCardMeta(
          label: 'Stock: ${_formatSuggestionQty(item.estoqueAtual)}',
        ),
        EnterpriseListCardMeta(
          label:
              'Saídas no período: ${_formatSuggestionInteger(item.totalSaidasPeriodo)}',
        ),
      ],
      actions: EnterpriseActionsMenuButton<String>(
        enabled: !isMutating,
        items: const [
          EnterpriseDropdownItem(
            value: 'editar',
            label: 'Editar',
            icon: Icons.edit_outlined,
          ),
          EnterpriseDropdownItem(
            value: 'remover',
            label: 'Remover',
            icon: Icons.delete_outline,
            destructive: true,
          ),
        ],
        onSelected: (action) {
          if (action == 'editar') onEdit();
          if (action == 'remover') onRemove();
        },
      ),
    );
  }
}

class _SuggestionFormDialog extends ConsumerStatefulWidget {
  const _SuggestionFormDialog({
    required this.parentRef,
    this.item,
    this.embedded = false,
  });

  final WidgetRef parentRef;
  final PurchaseSuggestionItem? item;
  final bool embedded;

  bool get isEditing => item != null;

  @override
  ConsumerState<_SuggestionFormDialog> createState() =>
      _SuggestionFormDialogState();
}

class _SuggestionFormDialogState extends ConsumerState<_SuggestionFormDialog> {
  late final TextEditingController _produtoController;
  late final TextEditingController _fornecedorController;
  late final TextEditingController _sugeridaController;
  late final TextEditingController _aprovadaController;

  ProdutoSearchResult? _selectedProduto;
  FornecedorDetalheModel? _selectedFornecedor;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _produtoController = TextEditingController(
      text: item?.produtoDisplayLabel ?? '',
    );
    _fornecedorController =
        TextEditingController(text: item?.fornecedorNome ?? '');
    _sugeridaController = TextEditingController(
      text: item != null
          ? _formatSuggestionInteger(item.quantidadeSugerida)
          : '0',
    );

    final defaultAprovada = item == null
        ? ''
        : _formatSuggestionInteger(
            item.quantidadeAprovada > 0
                ? item.quantidadeAprovada
                : item.quantidadeSugerida,
          );
    _aprovadaController = TextEditingController(text: defaultAprovada);

    if (item != null) {
      _selectedProduto = ProdutoSearchResult(
        id: item.produtoId,
        nomeComercial: item.produtoNome,
        dosagem: item.produtoDosagem,
        forma: item.produtoForma,
      );
      if (item.fornecedorId != null) {
        _selectedFornecedor = FornecedorDetalheModel(
          id: item.fornecedorId!,
          nome: item.fornecedorNome,
          ativo: true,
        );
      }
    }
  }

  @override
  void dispose() {
    _produtoController.dispose();
    _fornecedorController.dispose();
    _sugeridaController.dispose();
    _aprovadaController.dispose();
    super.dispose();
  }

  int? _parseApprovedQuantity() {
    final parsed =
        int.tryParse(_aprovadaController.text.trim().replaceAll(',', '.'));
    if (parsed == null || parsed < 0) {
      return null;
    }
    return parsed;
  }

  Future<void> _submit() async {
    final produto = _selectedProduto;
    final fornecedor = _selectedFornecedor;
    if (produto == null || fornecedor == null) {
      return;
    }

    final canEditApproved =
        ref.read(sessionAccessProvider).canEditPurchaseApprovedQuantity;
    int? quantidadeAprovada;
    if (canEditApproved) {
      if (_aprovadaController.text.trim().isEmpty) {
        return;
      }
      quantidadeAprovada = _parseApprovedQuantity();
      if (quantidadeAprovada == null) {
        return;
      }
    }

    setState(() => _isSubmitting = true);
    final controller =
        widget.parentRef.read(purchaseSuggestionsProvider.notifier);

    if (widget.isEditing) {
      await controller.updateSuggestion(
        produtoId: produto.id,
        supplierId: fornecedor.id,
        quantidadeAprovada: canEditApproved ? quantidadeAprovada : null,
      );
    } else {
      await controller.addManualSuggestion(
        produtoId: produto.id,
        supplierId: fornecedor.id,
        quantidadeAprovada: quantidadeAprovada,
      );
    }

    if (!mounted) return;
    final state = widget.parentRef.read(purchaseSuggestionsProvider);
    if (state.errorMessage == null) {
      AdaptiveNavigator.complete(context);
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildSupplierField(BuildContext context) {
    final s = context.spacing;
    final isEditing = widget.isEditing;

    if (isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EnterpriseTextField(
            controller: _produtoController,
            labelText: 'Produto',
            readOnly: true,
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
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
      ],
    );
  }

  Widget _buildFields(BuildContext context, {required bool canEditApproved}) {
    final s = context.spacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSupplierField(context),
        SizedBox(height: s.md),
        EnterpriseTextField(
          controller: _sugeridaController,
          labelText: 'Quantidade sugerida',
          readOnly: true,
        ),
        SizedBox(height: s.md),
        EnterpriseTextField(
          key: ValueKey('aprovada-$canEditApproved'),
          controller: _aprovadaController,
          labelText: 'Quantidade aprovada para compra',
          hintText: canEditApproved
              ? (widget.isEditing ? null : 'Informe a quantidade')
              : null,
          keyboardType: TextInputType.number,
          readOnly: !canEditApproved,
        ),
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    return [
      EnterpriseOverlayActions.secondary(
        label: 'Cancelar',
        onPressed:
            _isSubmitting ? null : () => AdaptiveNavigator.cancel(context),
      ),
      EnterpriseOverlayActions.primary(
        label: widget.isEditing ? 'Guardar' : 'Adicionar',
        onPressed: _selectedProduto == null ||
                _selectedFornecedor == null ||
                _isSubmitting
            ? null
            : _submit,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final canEditApproved = ref.watch(
      sessionAccessProvider.select((access) => access.canEditPurchaseApprovedQuantity),
    );
    final form = _buildFields(context, canEditApproved: canEditApproved);
    final actions = _buildActions(context);

    if (widget.embedded) {
      final isMobile = PharmaScreenLayout.isMobile(context);
      if (isMobile) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  PharmaScreenLayout.mobileHorizontalInset(context),
                  s.lg,
                  PharmaScreenLayout.mobileHorizontalInset(context),
                  s.lg,
                ),
                child: form,
              ),
            ),
            EnterpriseOverlayFooter(
              actions: actions,
              expandOnNarrow: true,
            ),
          ],
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          form,
          SizedBox(height: s.lg),
          EnterpriseOverlayFooter(
            actions: actions,
            expandOnNarrow: false,
          ),
        ],
      );
    }

    return PharmaResponsiveDialog(
      title: Text(
        widget.isEditing ? 'Editar sugestão' : 'Adicionar produto',
      ),
      content: form,
      actions: actions,
    );
  }
}
