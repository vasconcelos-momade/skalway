import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/extensions/async_value_extensions.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/responsive/responsive_builder.dart';
import '../../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../../shared/widgets/dialogs/enterprise_form_side_sheet.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/inputs/enterprise_select_field.dart';
import '../../../../../shared/widgets/inputs/enterprise_text_field.dart';
import '../../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../../shared/widgets/menus/enterprise_actions_menu_button.dart';
import '../../../../../shared/widgets/menus/enterprise_dropdown_menu.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../../../../../shared/widgets/tables/enterprise_table_cells.dart';
import '../../domain/entities/pharmacy_service.dart';
import '../providers/pharmacy_service_provider.dart';

class ServicesPage extends ConsumerStatefulWidget {
  const ServicesPage({super.key});

  @override
  ConsumerState<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends ConsumerState<ServicesPage> {
  late final TextEditingController _searchController;
  List<PharmacyService> _accumulatedItems = [];

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
    final state = ref.watch(pharmacyServiceListProvider);
    final controller = ref.read(pharmacyServiceListProvider.notifier);
    final statsAsync = ref.watch(pharmacyServiceStatsProvider);
    final t = context.pharmaTokens;
    final s = context.spacing;

    ref.listen(pharmacyServiceListProvider, (prev, next) {
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
        final stats = statsAsync.valueOrNull;
        final statsList = stats == null
            ? null
            : <EnterpriseStatCard>[
                EnterpriseStatCard(
                  title: 'Serviços',
                  value: '${stats['totalServicos'] ?? 0}',
                  icon: Icons.medical_services_outlined,
                  accent: StatCardAccent.info,
                ),
                EnterpriseStatCard(
                  title: 'Activos',
                  value: '${stats['servicosActivos'] ?? 0}',
                  icon: Icons.check_circle_outline,
                  accent: StatCardAccent.positive,
                ),
                EnterpriseStatCard(
                  title: 'Inactivos',
                  value: '${stats['servicosInactivos'] ?? 0}',
                  icon: Icons.pause_circle_outline,
                  accent: StatCardAccent.warning,
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
                      onPressed:
                          state.isLoading ? null : () => _openForm(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Novo serviço'),
                    ),
                  ],
            filters: null,
            child: EnterpriseAdaptiveListBody(
              isMobile: isMobile,
              isLoading: state.isLoading && state.items.isEmpty,
              errorText: state.errorMessage != null && state.items.isEmpty
                  ? state.errorMessage
                  : null,
              desktopToolbar: EnterpriseDesktopListToolbar(
                searchController: _searchController,
                searchHint: 'Pesquisar por nome...',
                isLoading: state.isLoading,
                onSearchSubmitted: controller.onSearchChanged,
                hasFilters: state.includeInactive,
                onClearFilters: state.isLoading
                    ? null
                    : () => controller.setIncludeInactive(false),
                filterWidgets: [
                  SizedBox(
                    width: 170,
                    child: EnterpriseSelectField<bool>(
                      label: 'Mostrar inactivos',
                      value: state.includeInactive,
                      options: const [
                        EnterpriseSelectOption(value: false, label: 'Não'),
                        EnterpriseSelectOption(value: true, label: 'Sim'),
                      ],
                      onChanged: state.isLoading
                          ? null
                          : (val) =>
                              controller.setIncludeInactive(val ?? false),
                    ),
                  ),
                ],
              ),
              desktopContent: EnterpriseDataTable(
                status: state.isLoading && state.items.isEmpty
                    ? EnterpriseTableStatus.loading
                    : state.items.isEmpty
                        ? EnterpriseTableStatus.empty
                        : EnterpriseTableStatus.data,
                isLoading: state.isLoading,
                emptyTitle: 'Nenhum registo encontrado',
                emptyMessage: 'Nenhum serviço encontrado',
                columns: [
                  enterpriseDataColumn(context, 'Nome'),
                  enterpriseDataColumn(context, 'Tipo'),
                  enterpriseDataColumn(context, 'Preço', numeric: true),
                  enterpriseDataColumn(context, 'Estado'),
                  enterpriseDataColumn(context, 'Ações'),
                ],
                rowCount: state.items.length,
                rowBuilder: (context, index) {
                  final item = state.items[index];
                  return DataRow(
                    cells: [
                      DataCell(TablePrimaryCell(item.nome)),
                      DataCell(
                        TableSecondaryCell(
                          pharmacyServiceTipoLabel(item.tipoServicoClinico),
                        ),
                      ),
                      DataCell(
                        TableNumericCell(
                          '${item.preco.toStringAsFixed(2)} MZN',
                        ),
                      ),
                      DataCell(_StatusChip(ativo: item.ativo)),
                      DataCell(
                        EnterpriseActionsMenuButton<String>(
                          compact: true,
                          items: const [
                            EnterpriseDropdownItem(
                              value: 'ver',
                              label: 'Visualizar',
                              icon: Icons.visibility_outlined,
                            ),
                            EnterpriseDropdownItem(
                              value: 'editar',
                              label: 'Editar',
                              icon: Icons.edit_outlined,
                            ),
                            EnterpriseDropdownItem(
                              value: 'excluir',
                              label: 'Eliminar',
                              icon: Icons.delete_outline,
                              destructive: true,
                            ),
                          ],
                          onSelected: (action) {
                            switch (action) {
                              case 'ver':
                                _openView(context, item);
                              case 'editar':
                                _openForm(context, service: item);
                              case 'excluir':
                                _confirmDelete(context, item);
                            }
                          },
                        ),
                      ),
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
                      itemLabel: 'serviços',
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
                  onSearchSubmitted: controller.onSearchChanged,
                ),
                itemCount: _accumulatedItems.length,
                itemBuilder: (context, index) {
                  final item = _accumulatedItems[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: s.sm),
                    child: EnterpriseListCard(
                      title: item.nome,
                      subtitle:
                          '${pharmacyServiceTipoLabel(item.tipoServicoClinico)} · ${item.preco.toStringAsFixed(2)} MZN',
                      trailing: _StatusChip(ativo: item.ativo),
                      onTap: () => _openView(context, item),
                      actions: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () =>
                                _openForm(context, service: item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmDelete(context, item),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                hasMore: state.hasMore,
                isLoading: state.isLoading,
                onLoadMore: () => controller.goToPage(state.page + 1),
                emptyMessage: 'Nenhum serviço encontrado',
                totalCount: state.totalCount,
                totalCountLabel: state.totalCount != null
                    ? 'Total: ${state.totalCount} serviço(s)'
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openForm(
    BuildContext context, {
    PharmacyService? service,
  }) async {
    final title = Text(service == null ? 'Novo serviço' : 'Editar serviço');
    final result = await AdaptiveNavigator.openPanel<Map<String, dynamic>>(
      context: context,
      routeSettings: RouteSettings(
        name: service == null
            ? '/pharmacy/services/novo'
            : '/pharmacy/services/${service.id}/editar',
      ),
      builder: (detailContext) {
        if (AdaptiveNavigator.isMobile(detailContext)) {
          return Scaffold(
            appBar: AppBar(title: title),
            body: SafeArea(
              child: _ServiceForm(
                service: service,
                embedded: true,
                showHeader: false,
                onClose: () => AdaptiveNavigator.cancel(detailContext),
              ),
            ),
          );
        }
        return _ServiceForm(
          service: service,
          embedded: true,
          onClose: () => AdaptiveNavigator.cancel(detailContext),
        );
      },
    );

    if (result == null || !mounted) return;
    try {
      final notifier = ref.read(pharmacyServiceListProvider.notifier);
      if (service == null) {
        await notifier.create(result);
        if (mounted) PharmaFeedback.success(context, 'Serviço criado.');
      } else {
        await notifier.update(service.id, result);
        if (mounted) PharmaFeedback.success(context, 'Serviço actualizado.');
      }
      ref.invalidate(pharmacyServiceStatsProvider);
    } on ApiFailure catch (e) {
      if (mounted) PharmaFeedback.error(context, e.message);
    }
  }

  Future<void> _openView(BuildContext context, PharmacyService service) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(service.nome),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: ${pharmacyServiceTipoLabel(service.tipoServicoClinico)}'),
            Text('Preço: ${service.preco.toStringAsFixed(2)} MZN'),
            Text('Estado: ${service.ativo ? 'Activo' : 'Inactivo'}'),
            if (service.taxRuleCodigo != null)
              Text('IVA: ${service.taxRuleCodigo}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _openForm(context, service: service);
            },
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PharmacyService service,
  ) async {
    final confirmed = await PharmaFeedback.confirm(
      context: context,
      title: 'Eliminar serviço',
      message:
          'O serviço «${service.nome}» será desactivado. Continuar?',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await ref.read(pharmacyServiceListProvider.notifier).delete(service.id);
      ref.invalidate(pharmacyServiceStatsProvider);
      if (mounted) PharmaFeedback.success(context, 'Serviço eliminado.');
    } on ApiFailure catch (e) {
      if (mounted) PharmaFeedback.error(context, e.message);
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.ativo});
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.sm,
        vertical: context.spacing.xxs,
      ),
      decoration: BoxDecoration(
        color: (ativo ? t.posSuccess : t.textMuted).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(t.radiusSm),
      ),
      child: Text(
        ativo ? 'Activo' : 'Inactivo',
        style: Theme.of(context).textTheme.erpCaption.copyWith(
              color: ativo ? t.posSuccess : t.textMuted,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ServiceForm extends ConsumerStatefulWidget {
  const _ServiceForm({
    this.service,
    this.embedded = false,
    this.showHeader = true,
    this.onClose,
  });

  final PharmacyService? service;
  final bool embedded;
  final bool showHeader;
  final VoidCallback? onClose;

  @override
  ConsumerState<_ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends ConsumerState<_ServiceForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _preco;
  late String _tipo;
  late bool _ativo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _nome = TextEditingController(text: s?.nome ?? '');
    _preco = TextEditingController(
      text: s == null ? '' : s.preco.toStringAsFixed(2),
    );
    _tipo = s?.tipoServicoClinico ?? 'OUTRO';
    _ativo = s?.ativo ?? true;
  }

  @override
  void dispose() {
    _nome.dispose();
    _preco.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final preco = double.tryParse(_preco.text.replaceAll(',', '.'));
    if (preco == null || preco < 0) {
      PharmaFeedback.error(context, 'Preço inválido.');
      return;
    }
    setState(() => _saving = true);
    final payload = <String, dynamic>{
      'nome': _nome.text.trim(),
      'tipoServicoClinico': _tipo,
      'preco': preco,
      'ativo': _ativo,
    };
    if (widget.embedded) {
      AdaptiveNavigator.pop(context, payload);
      return;
    }
    Navigator.of(context).pop(payload);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final formFields = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnterpriseTextFormField(
          controller: _nome,
          labelText: 'Nome',
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Nome obrigatório' : null,
        ),
        SizedBox(height: s.md),
        EnterpriseSelectField<String>(
          label: 'Tipo clínico',
          value: _tipo,
          options: [
            for (final tipo in pharmacyServiceTipos)
              EnterpriseSelectOption(
                value: tipo,
                label: pharmacyServiceTipoLabel(tipo),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _tipo = value);
          },
        ),
        SizedBox(height: s.md),
        EnterpriseTextFormField(
          controller: _preco,
          labelText: 'Preço (MZN)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          validator: (v) {
            final n = double.tryParse((v ?? '').replaceAll(',', '.'));
            if (n == null || n < 0) return 'Preço inválido';
            return null;
          },
        ),
        SizedBox(height: s.md),
        EnterpriseFormSwitch(
          label: 'Activo',
          value: _ativo,
          onChanged: (v) => setState(() => _ativo = v),
        ),
      ],
    );

    final actions = [
      TextButton(
        onPressed: _saving
            ? null
            : () {
                if (widget.onClose != null) {
                  widget.onClose!();
                } else {
                  Navigator.of(context).maybePop();
                }
              },
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _saving ? null : _submit,
        child: Text(widget.service == null ? 'Criar' : 'Guardar'),
      ),
    ];

    if (widget.embedded) {
      return Form(
        key: _formKey,
        child: EnterpriseFormSideSheet(
          title: Text(widget.service == null ? 'Novo serviço' : 'Editar serviço'),
          showHeader: widget.showHeader,
          onClose: widget.onClose,
          body: formFields,
          actions: actions,
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(s.md),
        children: [
          formFields,
          SizedBox(height: s.lg),
          ...actions,
        ],
      ),
    );
  }
}
