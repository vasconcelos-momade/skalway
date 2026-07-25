import 'package:flutter/material.dart';
import '../../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../../../../shared/widgets/tables/enterprise_pagination.dart';


import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/extensions/async_value_extensions.dart';
import '../../../../../core/constants/report_paths.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/responsive/responsive_builder.dart';
import '../../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/widgets/layout/adaptive_side_sheet.dart';
import '../../../../../shared/widgets/dialogs/enterprise_overlay_tokens.dart';
import '../../../../../shared/widgets/dialogs/pharma_responsive_dialog.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/inputs/enterprise_select_field.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../domain/entities/category.dart';
import '../../domain/fnm_categories.dart';
import '../providers/category_provider.dart';
import '../providers/category_stats_provider.dart';
import '../../../presentation/widgets/pharmacy_report_exports.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  late final TextEditingController _searchController;
  List<Category> _accumulatedItems = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryListProvider);
    final controller = ref.read(categoryListProvider.notifier);
    final statsAsync = ref.watch(categoryStatsProvider);
    final t = context.pharmaTokens;
    final s = context.spacing;
    final reportQuery = pharmacyReportQuery({
      if (_searchController.text.trim().isNotEmpty) 'q': _searchController.text.trim(),
    });

    ref.listen(categoryListProvider, (prev, next) {
      if (prev?.page != next.page ||
          prev?.query != next.query ||
          prev?.includeInactive != next.includeInactive) {
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

    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = !constraints.isTabletOrWider;

        final statsList = statsAsync.valueOrNull == null
            ? null
            : <EnterpriseStatCard>[
                EnterpriseStatCard(
                  title: 'Categorias',
                  value: '${statsAsync.valueOrNull?['totalCategorias'] ?? 0}',
                  icon: Icons.category_outlined,
                ),
                EnterpriseStatCard(
                  title: 'Produtos',
                  value: '${statsAsync.valueOrNull?['totalProdutos'] ?? 0}',
                  icon: Icons.inventory_2_outlined,
                ),
                EnterpriseStatCard(
                  title: 'Activas/Inactivas',
                  value:
                      '${statsAsync.valueOrNull?['categoriasActivas'] ?? 0}/${statsAsync.valueOrNull?['categoriasInactivas'] ?? 0}',
                  icon: Icons.toggle_on_outlined,
                ),
                EnterpriseStatCard(
                  title: 'Stock',
                  value: '${statsAsync.valueOrNull?['stockDisponivel'] ?? 0}',
                  icon: Icons.stacked_bar_chart_outlined,
                ),
              ];

        return Scaffold(
          backgroundColor: t.bgPrimary,
          floatingActionButton: isMobile
              ? FloatingActionButton(
                  onPressed: state.isLoading ? null : () => _openForm(context),
                  child: const Icon(Icons.add),
                )
              : null,
          body: EnterpriseModuleHub(
            mobileKpisHorizontalScroll: true,
            kpis: isMobile ? null : statsList,
            actions: isMobile
                ? null
                : [
                    FilledButton.icon(
                      onPressed: state.isLoading ? null : () => _openForm(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Nova categoria'),
                    ),
                  ],
            filters: null,
            child: EnterpriseAdaptiveListBody(
              isMobile: isMobile,
              isLoading: state.isLoading && state.items.isEmpty,
              errorText: state.errorMessage != null && state.items.isEmpty ? state.errorMessage : null,
              desktopToolbar: EnterpriseDesktopListToolbar(
                searchController: _searchController,
                searchHint: 'Pesquisar por nome...',
                isLoading: state.isLoading,
                onSearchSubmitted: controller.onSearchChanged,
                hasFilters: state.includeInactive,
                onClearFilters: state.isLoading ? null : () => controller.setIncludeInactive(false),
                trailingActions: pharmacyReportActions(
                  ref: ref,
                  enabled: !state.isLoading,
                  path: ReportPaths.pharmacyCategories,
                  queryParameters: reportQuery,
                  isIconButton: false,
                ),
                filterWidgets: [
                  SizedBox(
                    width: 170,
                    child: EnterpriseSelectField<bool>(
                      label: 'Mostrar inactivas',
                      value: state.includeInactive,
                      options: const [
                        EnterpriseSelectOption<bool>(value: false, label: 'Não'),
                        EnterpriseSelectOption<bool>(value: true, label: 'Sim'),
                      ],
                      onChanged: state.isLoading
                          ? null
                          : (val) =>
                              controller.setIncludeInactive(val ?? false),
                    ),
                  ),
                ],
              ),
              desktopContent: state.items.isEmpty && !state.isLoading
                  ? Center(
                      child: Text(
                        'Nenhuma categoria encontrada',
                        style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
                      ),
                    )
                  : EnterpriseDataTable(
                      columns: const [
                        DataColumn(label: Text('NOME')),
                        DataColumn(label: Text('DESCRIÇÃO')),
                        DataColumn(label: Text('PRODUTOS')),
                        DataColumn(label: Text('ESTADO')),
                        DataColumn(label: Text('AÇÕES')),
                      ],
                      rowCount: state.items.length,
                      rowBuilder: (context, index) {
                        final item = state.items[index];
                        return DataRow(
                          cells: [
                            DataCell(Text(fnmCategoryLabel(item.nome))),
                            DataCell(Text(item.descricao ?? '—')),
                            DataCell(Text('${item.productCount}')),
                            DataCell(_StatusChip(ativo: item.ativo)),
                            DataCell(PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(
                                minWidth: t.minTouchTarget * 0.6,
                                minHeight: t.minTouchTarget * 0.6,
                              ),
                              icon: Icon(Icons.more_vert, size: t.iconSm, color: t.textMuted),
                              onSelected: (action) {
                                switch (action) {
                                  case 'editar':
                                    _openForm(context, category: item);
                                    break;
                                  case 'excluir':
                                    _confirmDelete(context, item);
                                    break;
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'editar', child: Text('Editar')),
                                PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                              ],
                            )),
                          ],
                        );
                      },
                    ),
              desktopPagination: state.totalCount != null
                  ? EnterprisePagination(
                      page: state.page,
                      pageSize: state.pageSize,
                      totalCount: state.totalCount!,
                      isBusy: state.isLoading,
                      itemLabel: 'categorias',
                      onPageChanged: controller.goToPage,
                      onPageSizeChanged: controller.setPageSize,
                    )
                  : null,
              mobileList: EnterpriseMobileScrollList(
                kpis: statsList,
                stickyHeader: EnterpriseMobileToolbar(
                  searchController: _searchController,
                  searchHint: 'Pesquisar por nome...',
                  enabled: !state.isLoading,
                  isLoading: state.isLoading,
                  hasFilters: state.includeInactive,
                  reportAction: pharmacyReportActions(
                    ref: ref,
                    enabled: !state.isLoading,
                    path: ReportPaths.pharmacyCategories,
                    queryParameters: reportQuery,
                    expandChild: true,
                    buttonLabel: 'Exportar..',
                  ).single,
                  onSearchSubmitted: controller.onSearchChanged,
                  onOpenFilters: () {
                    final scheme = Theme.of(context).colorScheme;
                    showModalBottomSheet<void>(
                      context: context,
                      useRootNavigator: true,
                      isScrollControlled: true,
                      barrierColor: enterpriseOverlayScrim(context),
                      backgroundColor: scheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(context.pharmaTokens.radiusXl),
                        ),
                      ),
                      builder: (sheetContext) => SafeArea(
                        child: Padding(
                          padding: EdgeInsets.all(s.md),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40,
                                height: 4,
                                margin: EdgeInsets.only(bottom: s.md),
                                decoration: BoxDecoration(
                                  color: context.pharmaTokens.textMuted.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(context.pharmaTokens.radiusMd / 2),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Filtros',
                                    style: Theme.of(context).textTheme.erpCardTitle.copyWith(
                                          color: context.pharmaTokens.textPrimary,
                                        ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close_rounded, color: context.pharmaTokens.textMuted, size: context.pharmaTokens.iconSm),
                                    onPressed: () => Navigator.of(sheetContext).pop(),
                                  ),
                                ],
                              ),
                              Divider(height: 1, color: context.pharmaTokens.border.withValues(alpha: 0.45)),
                              SizedBox(height: s.md),
                              SwitchListTile(
                                title: const Text('Mostrar inactivas'),
                                value: state.includeInactive,
                                onChanged: (val) {
                                  controller.setIncludeInactive(val);
                                  Navigator.of(sheetContext).pop();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  showRefreshButton: false,
                  onClearFilters: () async => controller.setIncludeInactive(false),
                  onRefresh: () async => controller.goToPage(1),
                ),
                itemCount: _accumulatedItems.length,
                itemBuilder: (context, index) {
                  final category = _accumulatedItems[index];
                  return _CategoryMobileCard(
                    category: category,
                    onTap: () => _openForm(context, category: category),
                    onEdit: () => _openForm(context, category: category),
                    onDelete: () => _confirmDelete(context, category),
                  );
                },
                hasMore: state.hasMore,
                isLoading: state.isLoading,
                onLoadMore: () => controller.goToPage(state.page + 1),
                emptyMessage: 'Nenhuma categoria encontrada',
                totalCount: state.totalCount,
                totalCountLabel: state.totalCount != null
                    ? 'Total: ${state.totalCount} categoria(s)'
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openForm(BuildContext context, {Category? category}) async {
    final title = Text(
      category == null ? 'Nova categoria' : 'Editar categoria',
    );
    final routeSettings = RouteSettings(
      name: category == null
          ? '/categorias/nova'
          : '/categorias/${category.id}/editar',
    );
    
    final width = AdaptiveNavigator.widthOf(context);
    final panelWidth = width >= AdaptiveSideSheetMetrics.desktopBreakpoint
        ? 520.0
        : 480.0;

    final result = await AdaptiveNavigator.openPanel<Map<String, dynamic>>(
      context: context,
      sideSheetWidth: panelWidth,
      routeSettings: routeSettings,
      builder: (detailContext) {
        if (AdaptiveNavigator.isMobile(detailContext)) {
          return Scaffold(
            appBar: AppBar(title: title),
            body: SafeArea(
              child: _CategoryFormDialog(
                category: category,
                embedded: true,
                pinnedFooter: true,
                showHeader: false,
                onClose: () => AdaptiveNavigator.cancel(detailContext),
              ),
            ),
          );
        }
        return _CategoryFormDialog(
          category: category,
          embedded: true,
          pinnedFooter: true,
          showHeader: true,
          onClose: () => AdaptiveNavigator.cancel(detailContext),
        );
      },
    );
    
    if (result == null || !context.mounted) return;
    final notifier = ref.read(categoryListProvider.notifier);
    try {
      if (category == null) {
        await notifier.create(result);
        if (!context.mounted) return;
        PharmaFeedback.success(context, 'Categoria criada.');
      } else {
        await notifier.update(category.id, result);
        if (!context.mounted) return;
        PharmaFeedback.success(context, 'Categoria actualizada.');
      }
    } on ApiFailure catch (e) {
      if (!context.mounted) return;
      PharmaFeedback.error(context, e.message);
    } catch (e) {
      if (!context.mounted) return;
      PharmaFeedback.error(context, e.toString());
    }
  }

  Future<void> _confirmDelete(BuildContext context, Category category) async {
    final confirmed = await PharmaFeedback.confirm(
      context: context,
      title: 'Excluir categoria',
      message:
          'A categoria «${category.nome}» será desactivada. Não é possível excluir se existirem produtos vinculados.',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(categoryListProvider.notifier).delete(category.id);
      if (!context.mounted) return;
      PharmaFeedback.success(context, 'Categoria excluída.');
    } on ApiFailure catch (e) {
      if (!context.mounted) return;
      PharmaFeedback.error(context, e.message);
    }
  }
}

class _CategoryFormDialog extends StatefulWidget {
  const _CategoryFormDialog({
    this.category,
    this.embedded = false,
    this.pinnedFooter = false,
    this.showHeader = false,
    this.onClose,
  });
  final Category? category;
  final bool embedded;
  final bool pinnedFooter;
  final bool showHeader;
  final VoidCallback? onClose;

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descricao;
  late String? _nomeSelecionado;
  late bool _ativo;

  @override
  void initState() {
    super.initState();
    _descricao = TextEditingController(text: widget.category?.descricao ?? '');
    _nomeSelecionado = widget.category?.nome;
    _ativo = widget.category?.ativo ?? true;
  }

  @override
  void dispose() {
    _descricao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final nomeOptions = <String>[
      ...kFnmCategories,
      if (_nomeSelecionado != null &&
          _nomeSelecionado!.trim().isNotEmpty &&
          !kFnmCategories.contains(_nomeSelecionado)) _nomeSelecionado!,
    ];

    final formFields = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: nomeOptions.contains(_nomeSelecionado)
              ? _nomeSelecionado
              : null,
          decoration: const InputDecoration(labelText: 'Categoria FNM *'),
          items: nomeOptions
              .map(
                (nome) => DropdownMenuItem<String>(
                  value: nome,
                  child: Text(fnmCategoryLabel(nome)),
                ),
              )
              .toList(growable: false),
          onChanged: (value) => setState(() => _nomeSelecionado = value),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Categoria obrigatória' : null,
        ),
        SizedBox(height: s.md),
        TextFormField(
          controller: _descricao,
          decoration: const InputDecoration(labelText: 'Descrição'),
          maxLines: 2,
        ),
        SizedBox(height: s.md),
        SwitchListTile(
          title: const Text('Activa'),
          value: _ativo,
          onChanged: (v) => setState(() => _ativo = v),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );

    final actions = [
      OutlinedButton(
        onPressed: () => AdaptiveNavigator.cancel(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          AdaptiveNavigator.complete(context, {
            'nome': _nomeSelecionado!.trim(),
            'descricao': _descricao.text.trim().isEmpty
                ? null
                : _descricao.text.trim(),
            'ativo': _ativo,
          });
        },
        child: Text(widget.category == null ? 'Criar' : 'Guardar'),
      ),
    ];

    final actionsSection = PharmaResponsiveDialogActions(
      breakpoint: pharmaDialogBreakpointForWidth(MediaQuery.sizeOf(context).width),
      children: actions,
    );

    final form = Form(
      key: _formKey,
      child: widget.pinnedFooter
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.showHeader) ...[
                  Padding(
                    padding: EdgeInsets.fromLTRB(s.md, s.md, s.sm, s.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.category == null ? 'Nova categoria' : 'Editar categoria',
                            style: Theme.of(context).textTheme.erpCardTitle,
                          ),
                        ),
                        if (widget.onClose != null)
                          IconButton(
                            onPressed: widget.onClose,
                            icon: const Icon(Icons.close),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(s.md),
                    child: formFields,
                  ),
                ),
                const Divider(height: 1),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.all(s.md),
                    child: actionsSection,
                  ),
                ),
              ],
            )
          : formFields,
    );

    if (widget.embedded) {
      if (widget.pinnedFooter) {
        return form;
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          form,
          SizedBox(height: s.md),
          actionsSection,
        ],
      );
    }

    return PharmaResponsiveDialog(
      title: Text(widget.category == null ? 'Nova categoria' : 'Editar categoria'),
      content: form,
      actions: actions,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.ativo});
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final color = ativo ? t.brandGreen : t.textMuted;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        ativo ? 'Activa' : 'Inactiva',
        style: Theme.of(context).textTheme.erpCaption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _CategoryMobileCard extends StatelessWidget {
  const _CategoryMobileCard({
    required this.category,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Category category;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final descricao = category.descricao?.trim();

    return EnterpriseListCard(
      title: fnmCategoryLabel(category.nome),
      subtitle: descricao != null && descricao.isNotEmpty ? descricao : null,
      chip: EnterpriseStatusChip(
        label: category.ativo ? 'Activa' : 'Inactiva',
        color: category.ativo ? t.brandGreen : t.textMuted,
      ),
      trailingMeta: EnterpriseListCardMeta(
        label: 'Produtos: ${category.productCount}',
        alignEnd: true,
        emphasized: true,
      ),
      onTap: onTap,
      actions: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          minWidth: t.minTouchTarget * 0.6,
          minHeight: t.minTouchTarget * 0.6,
        ),
        icon: Icon(Icons.more_vert, size: t.iconSm, color: t.textMuted),
        onSelected: (action) {
          switch (action) {
            case 'editar':
              onEdit();
              break;
            case 'excluir':
              onDelete();
              break;
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'editar', child: Text('Editar')),
          PopupMenuItem(value: 'excluir', child: Text('Excluir')),
        ],
      ),
    );
  }
}
