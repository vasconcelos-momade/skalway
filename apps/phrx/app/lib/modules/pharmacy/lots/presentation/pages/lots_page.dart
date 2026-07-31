import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/extensions/async_value_extensions.dart';
import '../../../../../core/constants/report_paths.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../core/utils/lote_stock_utils.dart';
import '../../../../../shared/responsive/responsive_builder.dart';
import '../../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/inputs/enterprise_select_field.dart';
import '../../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../../shared/widgets/menus/enterprise_actions_menu_button.dart';
import '../../../../../shared/widgets/menus/enterprise_dropdown_menu.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../../shared/widgets/tables/enterprise_table_cells.dart';
import '../../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../providers/lots_provider.dart';
import '../widgets/open_lote_details.dart';
import '../widgets/lot_actions_helper.dart';
import '../../../presentation/widgets/pharmacy_report_exports.dart';
import '../../../../../shared/refresh/page_refresh.dart';

class LotsPage extends ConsumerStatefulWidget {
  const LotsPage({super.key});

  @override
  ConsumerState<LotsPage> createState() => _LotsPageState();
}

class _LotsPageState extends ConsumerState<LotsPage> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _accumulatedItems = [];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Color _validadeColor(BuildContext context, String? indicador) {
    final t = context.pharmaTokens;
    switch (indicador) {
      case 'EXPIRADO':
        return t.posDanger;
      case '30_DIAS':
        return t.posWarning;
      case '60_DIAS':
        return t.quarantine;
      default:
        return t.brandGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(lotsViewProvider);
    final controller = ref.read(lotsViewProvider.notifier);
    final current = asyncState.valueOrNull;
    final dash = current?.dashboard;
    final t = context.pharmaTokens;
    final s = context.spacing;
    final reportPath = current?.expirado == true
        ? ReportPaths.pharmacyLotsExpired
        : ReportPaths.pharmacyLotsActive;
    final reportQuery = <String, dynamic>{
      if ((current?.query ?? '').isNotEmpty) 'q': current!.query,
      if (current?.estadoSanitario != null)
        'estadoSanitario': current!.estadoSanitario,
      if (current?.disponibilidade != null)
        'disponibilidade': current!.disponibilidade,
    };
    final hasFilters =
        (current?.estadoSanitario != null) ||
        (current?.disponibilidade != null) ||
        (current?.expirado != null);
    final kpis = dash == null
        ? null
        : [
            EnterpriseStatCard(
              title: 'Total de lotes',
              value: '${dash['totalLotes'] ?? 0}',
              icon: Icons.inventory_2_outlined,
            ),
            EnterpriseStatCard(
              title: 'Disponíveis',
              value: '${dash['lotesDisponiveis'] ?? 0}',
              icon: Icons.check_circle_outline,
            ),
            EnterpriseStatCard(
              title: 'Sanitários',
              value: '${dash['lotesSanitarios'] ?? 0}',
              icon: Icons.health_and_safety_outlined,
            ),
            EnterpriseStatCard(
              title: 'Alertas',
              value: '${dash['alertasOperacionais'] ?? 0}',
              icon: Icons.notifications_active_outlined,
            ),
          ];

    if (current != null && _search.text != current.query) {
      _search.value = TextEditingValue(
        text: current.query,
        selection: TextSelection.collapsed(offset: current.query.length),
      );
    }

    ref.listen(lotsViewProvider, (prev, next) {
      final previous = prev?.valueOrNull;
      final upcoming = next.valueOrNull;
      if (upcoming == null) return;

      if (previous?.page != upcoming.page ||
          previous?.query != upcoming.query ||
          previous?.estadoSanitario != upcoming.estadoSanitario ||
          previous?.disponibilidade != upcoming.disponibilidade ||
          previous?.expirado != upcoming.expirado ||
          previous?.pageSize != upcoming.pageSize) {
        if (upcoming.page == 1) {
          _accumulatedItems = List.of(upcoming.items);
        } else {
          final newItems = upcoming.items
              .where(
                (e) => !_accumulatedItems.any(
                  (a) => a['id']?.toString() == e['id']?.toString(),
                ),
              )
              .toList();
          _accumulatedItems.addAll(newItems);
        }
      } else if (previous?.items != upcoming.items && upcoming.page == 1) {
        _accumulatedItems = List.of(upcoming.items);
      }
    });

    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = !constraints.isTabletOrWider;

        return PageRefreshBinder(
      onRefresh: () => controller.refresh(force: true),
      child: EnterpriseModuleHub(
          mobileKpisHorizontalScroll: true,
          kpis: isMobile ? null : kpis,
          actions: null,
          filters: null,
          child: Column(
            children: [
              if (!isMobile && asyncState.isLoading)
                const LinearProgressIndicator(),
              if (!isMobile && asyncState.hasError)
                Padding(
                  padding: EdgeInsets.only(bottom: s.sm),
                  child: Text(
                    asyncState.error.toString(),
                    style: Theme.of(
                      context,
                    ).textTheme.erpBody.copyWith(color: t.posDanger),
                  ),
                ),
              if (!isMobile)
                Padding(
                  padding: EdgeInsets.only(bottom: s.md),
                  child: _LotsDesktopToolbar(
                    searchController: _search,
                    state: current,
                    isLoading: asyncState.isLoading,
                    onSearchSubmitted: controller.setSearch,
                    onEstadoSanitarioChanged: controller.setEstadoSanitario,
                    onDisponibilidadeChanged: controller.setDisponibilidade,
                    onExpiradoChanged: controller.setExpirado,
                    trailingActions: [
                      ...pharmacyReportActions(
                        ref: ref,
                        enabled: !asyncState.isLoading,
                        path: reportPath,
                        queryParameters: reportQuery,
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: isMobile
                    ? EnterpriseMobileScrollList(
                        kpis: kpis,
                        errorText: asyncState.hasError
                            ? asyncState.error.toString()
                            : null,
                        stickyHeader: EnterpriseMobileToolbar(
                          searchController: _search,
                          searchHint: 'Produto ou nº lote...',
                          enabled: !asyncState.isLoading,
                          isLoading: asyncState.isLoading,
                          hasFilters: hasFilters,
                          reportAction: pharmacyReportActions(
                            ref: ref,
                            enabled: !asyncState.isLoading,
                            path: reportPath,
                            queryParameters: reportQuery,
                            expandChild: true,
                            buttonLabel: 'Exportar..',
                          ).single,
                          onSearchSubmitted: controller.setSearch,
                          onOpenFilters: () =>
                              _openMobileFilters(context, controller, current),
                          onClearFilters: () async {
                            await controller.setEstadoSanitario(null);
                            await controller.setDisponibilidade(null);
                            await controller.setExpirado(null);
                          },
                          onRefresh: () => controller.refresh(force: true),
                        ),
                        itemCount: _accumulatedItems.length,
                        itemBuilder: (context, index) {
                          final lote = _accumulatedItems[index];
                          return _LoteMobileCard(
                            lote: lote,
                            isBusy:
                                current?.actionLoteId == lote['id']?.toString(),
                            validadeColor: (indicador) =>
                                _validadeColor(context, indicador),
                            onTap: () =>
                                _openLoteDetails(lote['id']?.toString() ?? ''),
                            onAction: (action) => _handleAction(action, lote),
                          );
                        },
                        hasMore: current?.hasMore ?? false,
                        isLoading: asyncState.isLoading,
                        onLoadMore: () =>
                            controller.goToPage((current?.page ?? 1) + 1),
                        emptyMessage: 'Nenhum lote encontrado',
                        totalCount: current?.totalCount,
                        totalCountLabel: current?.totalCount != null
                            ? 'Total: ${current!.totalCount} lote(s)'
                            : null,
                      )
                    : (current?.items.isEmpty ?? true) && !asyncState.isLoading
                    ? const Center(child: Text('Nenhum lote encontrado'))
                    : EnterpriseDataTable(
                        columns: [
                          enterpriseDataColumn(context, 'Produto'),
                          enterpriseDataColumn(context, 'Lote'),
                          enterpriseDataColumn(context, 'Validade'),
                          enterpriseDataColumn(context, 'Dias restantes', numeric: true),
                          enterpriseDataColumn(context, 'Stock', numeric: true),
                          enterpriseDataColumn(context, 'P. compra', numeric: true),
                          enterpriseDataColumn(context, 'P. venda', numeric: true),
                          enterpriseDataColumn(context, 'Estado'),
                          enterpriseDataColumn(context, 'Alertas'),
                          enterpriseDataColumn(context, 'Ações'),
                        ],
                        rowCount: current?.items.length ?? 0,
                        rowBuilder: (context, index) {
                          final item = current!.items[index];
                          final loteId = item['id']?.toString() ?? '';
                          final color = _validadeColor(
                            context,
                            item['indicadorValidade'] as String?,
                          );
                          final isBusy = current.actionLoteId == loteId;
                          return DataRow(
                            onSelectChanged: null,
                            cells: [
                              DataCell(
                                TablePrimaryCell(
                                  item['produtoNomeComercial']?.toString() ??
                                      item['produtoNome']?.toString() ??
                                      '—',
                                ),
                              ),
                              DataCell(
                                TablePrimaryCell(
                                  item['numeroLote']?.toString() ?? '—',
                                  subtitle: _loteSecondaryStatus(item),
                                ),
                              ),
                              DataCell(
                                TableMetadataCell(
                                  item['dataValidade']?.toString().substring(0, 10),
                                  color: color,
                                ),
                              ),
                              DataCell(
                                TableNumericCell(_diasRestantesLabel(item['dataValidade'])),
                              ),
                              DataCell(
                                TableNumericCell(LoteStockUtils.formatDisponivel(item)),
                              ),
                              DataCell(
                                TableNumericCell(item['precoCompra']?.toString() ?? '—'),
                              ),
                              DataCell(
                                TableNumericCell(item['precoVenda']?.toString() ?? '—'),
                              ),
                              DataCell(
                                TableStatusCell(
                                  label: item['estadoSanitario']?.toString() ?? '—',
                                  showDot: false,
                                ),
                              ),
                              DataCell(TableSecondaryCell(_alertaLabel(item))),
                              DataCell(
                                isBusy
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : EnterpriseActionsMenuButton<String>(
                                        tooltip: 'Acções do lote',
                                        items: [
                                          const EnterpriseDropdownItem(
                                            value: 'editar_precos',
                                            label: 'Editar preços do lote',
                                            icon: Icons.price_change_outlined,
                                          ),
                                          const EnterpriseDropdownItem(
                                            value: 'editar_info',
                                            label:
                                                'Editar informações do lote',
                                            icon: Icons.edit_outlined,
                                          ),
                                          if (LotActionsHelper.canMoveToQuarentena(
                                            item,
                                          ))
                                            const EnterpriseDropdownItem(
                                              value: 'quarentena',
                                              label: 'Mover para Quarentena',
                                              icon: Icons.warning_amber_outlined,
                                            ),
                                          if (LotActionsHelper.canRevertQuarentena(
                                            item,
                                          ))
                                            const EnterpriseDropdownItem(
                                              value: 'reverter',
                                              label: 'Liberar lote',
                                              icon: Icons.check_circle_outline,
                                            ),
                                          const EnterpriseDropdownItem(
                                            value: 'historico',
                                            label:
                                                'Visualizar histórico do lote',
                                            icon: Icons.history,
                                          ),
                                          const EnterpriseDropdownItem(
                                            value: 'recall',
                                            label: 'Executar Recall',
                                            icon: Icons.report_outlined,
                                          ),
                                          const EnterpriseDropdownItem(
                                            value: 'devolver_fornecedor',
                                            label:
                                                'Devolver lote ao fornecedor',
                                            icon: Icons.undo,
                                          ),
                                        ],
                                        onSelected: (action) =>
                                            _handleAction(action, item),
                                      ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
              if (!isMobile && current?.totalCount != null)
                EnterprisePagination(
                  page: current?.page ?? 1,
                  pageSize: current?.pageSize ?? 20,
                  totalCount: current!.totalCount!,
                  itemLabel: 'lotes',
                  onPageChanged: controller.goToPage,
                  onPageSizeChanged: controller.setPageSize,
                  isBusy: asyncState.isLoading,
                ),
            ],
          ),
        ),
    );
      },
    );
  }

  Future<void> _handleAction(String action, Map<String, dynamic> lote) async {
    final loteId = lote['id']?.toString() ?? '';
    if (loteId.isEmpty) return;

    switch (action) {
      case 'editar_precos':
      case 'editar_info':
      case 'recall':
      case 'devolver_fornecedor':
        _showActionPendingMessage(action);
        return;
      case 'quarentena':
        await LotActionsHelper.moveToQuarentena(context, ref, lote);
        return;
      case 'reverter':
        await LotActionsHelper.revertQuarentena(context, ref, lote);
        return;
      case 'historico':
        await LotActionsHelper.showHistory(
          context,
          ref,
          loteId,
          numeroLote: lote['numeroLote']?.toString(),
        );
        return;
    }
  }

  void _showActionPendingMessage(String action) {
    final label = switch (action) {
      'editar_precos' => 'Editar preços do lote',
      'editar_info' => 'Editar informações do lote',
      'recall' => 'Executar Recall',
      'devolver_fornecedor' => 'Devolver lote ao fornecedor',
      _ => action,
    };
    // TODO: integrate with backend
    PharmaFeedback.info(context, '$label será integrado com o fluxo backend existente.');
  }

  String _loteSecondaryStatus(Map<String, dynamic> item) {
    final estado = item['estadoSanitario']?.toString().toUpperCase();
    if (estado == 'EXPIRADO') return 'EXPIRADO';
    if (estado == 'QUARENTENA') return 'BLOQUEADO';
    final dias = _diasRestantes(item['dataValidade']);
    if (dias == null) return 'Sem validade';
    if (dias < 0) return 'EXPIRADO';
    return 'Expira em $dias dias';
  }

  int? _diasRestantes(dynamic dataValidade) {
    if (dataValidade == null) return null;
    final parsed = DateTime.tryParse(dataValidade.toString());
    if (parsed == null) return null;
    final today = DateTime.now();
    final end = DateTime(parsed.year, parsed.month, parsed.day);
    final start = DateTime(today.year, today.month, today.day);
    return end.difference(start).inDays;
  }

  String _diasRestantesLabel(dynamic dataValidade) {
    final dias = _diasRestantes(dataValidade);
    if (dias == null) return '—';
    if (dias < 0) return 'Vencido';
    return '$dias';
  }

  String _alertaLabel(Map<String, dynamic> item) {
    final indicador = item['indicadorValidade']?.toString().toUpperCase();
    final estado = item['estadoSanitario']?.toString().toUpperCase();
    if (estado == 'QUARENTENA') return 'Quarentena';
    if (estado == 'RECALL') return 'Recall';
    if (indicador == 'EXPIRADO' || estado == 'EXPIRADO') return 'Expirado';
    if (indicador == '30_DIAS') return 'Validade crítica';
    if (indicador == '60_DIAS') return 'Próximo da validade';
    return 'Sem alerta';
  }

  Future<void> _openLoteDetails(String loteId) =>
      openLoteDetails(context, loteId);

  void _openMobileFilters(
    BuildContext context,
    LotsViewController controller,
    LotsViewState? state,
  ) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _LotsFiltersBottomSheet(
        initialEstadoSanitario: state?.estadoSanitario,
        initialDisponibilidade: state?.disponibilidade,
        initialExpirado: state?.expirado == true,
        onApply: (estadoSanitario, disponibilidade, expirado) async {
          await controller.setEstadoSanitario(estadoSanitario);
          await controller.setDisponibilidade(disponibilidade);
          await controller.setExpirado(expirado ? true : null);
        },
      ),
    );
  }
}

class _LotsFiltersBottomSheet extends StatefulWidget {
  const _LotsFiltersBottomSheet({
    required this.initialEstadoSanitario,
    required this.initialDisponibilidade,
    required this.initialExpirado,
    required this.onApply,
  });

  final String? initialEstadoSanitario;
  final String? initialDisponibilidade;
  final bool initialExpirado;
  final Future<void> Function(
    String? estadoSanitario,
    String? disponibilidade,
    bool expirado,
  )
  onApply;

  @override
  State<_LotsFiltersBottomSheet> createState() =>
      _LotsFiltersBottomSheetState();
}

class _LotsFiltersBottomSheetState extends State<_LotsFiltersBottomSheet> {
  late String? _estadoSanitario = widget.initialEstadoSanitario;
  late String? _disponibilidade = widget.initialDisponibilidade;
  late bool _expirado = widget.initialExpirado;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        s.md,
        s.md,
        s.md,
        s.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Filtros', style: Theme.of(context).textTheme.erpSectionTitle),
          SizedBox(height: s.md),
          EnterpriseSelectField<String>(
            label: 'Estado sanitário',
            value: _estadoSanitario,
            emptyLabel: 'Todos',
            enabled: !_submitting,
            options: const [
              EnterpriseSelectOption(value: 'VALIDO', label: 'Válido'),
              EnterpriseSelectOption(value: 'EXPIRADO', label: 'Expirado'),
              EnterpriseSelectOption(value: 'QUARENTENA', label: 'Quarentena'),
              EnterpriseSelectOption(value: 'RECALL', label: 'Recall'),
            ],
            onChanged: (value) => setState(() => _estadoSanitario = value),
          ),
          SizedBox(height: s.md),
          EnterpriseSelectField<String>(
            label: 'Disponibilidade',
            value: _disponibilidade,
            emptyLabel: 'Todas',
            enabled: !_submitting,
            options: const [
              EnterpriseSelectOption(value: 'DISPONIVEL', label: 'Disponível'),
              EnterpriseSelectOption(value: 'RESERVADO', label: 'Reservado'),
              EnterpriseSelectOption(value: 'BLOQUEADO', label: 'Bloqueado'),
              EnterpriseSelectOption(value: 'INDISPONIVEL', label: 'Indisponível'),
            ],
            onChanged: (value) => setState(() => _disponibilidade = value),
          ),
          SizedBox(height: s.md),
          FilterChip(
            label: const Text('Mostrar apenas expirados'),
            selected: _expirado,
            onSelected: _submitting
                ? null
                : (value) => setState(() => _expirado = value),
          ),
          SizedBox(height: s.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () {
                          setState(() {
                            _estadoSanitario = null;
                            _disponibilidade = null;
                            _expirado = false;
                          });
                        },
                  child: const Text('Limpar'),
                ),
              ),
              SizedBox(width: s.sm),
              Expanded(
                child: FilledButton(
                  onPressed: _submitting
                      ? null
                      : () async {
                          setState(() => _submitting = true);
                          await widget.onApply(
                            _estadoSanitario,
                            _disponibilidade,
                            _expirado,
                          );
                          if (context.mounted) Navigator.of(context).pop();
                        },
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LotsDesktopToolbar extends StatefulWidget {
  const _LotsDesktopToolbar({
    required this.searchController,
    required this.state,
    required this.isLoading,
    required this.onSearchSubmitted,
    required this.onEstadoSanitarioChanged,
    required this.onDisponibilidadeChanged,
    required this.onExpiradoChanged,
    required this.trailingActions,
  });

  final TextEditingController searchController;
  final LotsViewState? state;
  final bool isLoading;
  final ValueChanged<String> onSearchSubmitted;
  final ValueChanged<String?> onEstadoSanitarioChanged;
  final ValueChanged<String?> onDisponibilidadeChanged;
  final ValueChanged<bool?> onExpiradoChanged;
  final List<Widget> trailingActions;

  @override
  State<_LotsDesktopToolbar> createState() => _LotsDesktopToolbarState();
}

class _LotsDesktopToolbarState extends State<_LotsDesktopToolbar> {
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final hasFilters =
        (state?.estadoSanitario != null) ||
        (state?.disponibilidade != null) ||
        (state?.expirado != null);

    return EnterpriseDesktopListToolbar(
      searchController: widget.searchController,
      searchHint: 'Pesquisar produto ou nº lote...',
      isLoading: widget.isLoading,
      onSearchSubmitted: widget.onSearchSubmitted,
      hasFilters: hasFilters,
      onClearFilters: () {
        widget.onEstadoSanitarioChanged(null);
        widget.onDisponibilidadeChanged(null);
        widget.onExpiradoChanged(null);
      },
      onApplyFilters: () {},
      filterWidgets: [
        EnterpriseSelectField<String>(
          key: ValueKey('lote-estado-${state?.estadoSanitario}'),
          label: 'Estado sanitário',
          emptyLabel: 'Todos',
          value: state?.estadoSanitario,
          options: const [
            EnterpriseSelectOption(value: 'VALIDO', label: 'Válido'),
            EnterpriseSelectOption(value: 'EXPIRADO', label: 'Expirado'),
            EnterpriseSelectOption(value: 'QUARENTENA', label: 'Quarentena'),
            EnterpriseSelectOption(value: 'RECALL', label: 'Recall'),
          ],
          onChanged: widget.isLoading ? null : widget.onEstadoSanitarioChanged,
        ),
        EnterpriseSelectField<String>(
          key: ValueKey('lote-disp-${state?.disponibilidade}'),
          label: 'Disponibilidade',
          emptyLabel: 'Todas',
          value: state?.disponibilidade,
          options: const [
            EnterpriseSelectOption(value: 'DISPONIVEL', label: 'Disponível'),
            EnterpriseSelectOption(value: 'RESERVADO', label: 'Reservado'),
            EnterpriseSelectOption(value: 'BLOQUEADO', label: 'Bloqueado'),
            EnterpriseSelectOption(value: 'INDISPONIVEL', label: 'Indisponível'),
          ],
          onChanged: widget.isLoading ? null : widget.onDisponibilidadeChanged,
        ),
        EnterpriseSelectField<bool>(
          key: ValueKey('lote-exp-${state?.expirado}'),
          label: 'Validade',
          emptyLabel: 'Todas',
          value: state?.expirado,
          options: const [
            EnterpriseSelectOption(value: true, label: 'Expirados'),
          ],
          onChanged: widget.isLoading ? null : widget.onExpiradoChanged,
        ),
      ],
      trailingActions: widget.trailingActions,
    );
  }
}

class _LoteMobileCard extends StatelessWidget {
  const _LoteMobileCard({
    required this.lote,
    required this.isBusy,
    required this.validadeColor,
    required this.onTap,
    required this.onAction,
  });

  final Map<String, dynamic> lote;
  final bool isBusy;
  final Color Function(String? indicador) validadeColor;
  final VoidCallback onTap;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final theme = Theme.of(context);
    final color = validadeColor(lote['indicadorValidade'] as String?);

    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(t.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: s.md, vertical: s.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: t.iconSm,
                    color: t.textPrimary,
                  ),
                  SizedBox(width: s.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lote['produtoNomeComercial'] ?? lote['produtoNome']?.toString() ?? '—',
                          style: theme.textTheme.erpCardTitle.copyWith(
                            color: t.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: s.xxs),
                        Text(
                          'Lote: ${lote['numeroLote']?.toString() ?? '—'} • ${_secondaryStatus(lote)}',
                          style: theme.textTheme.erpBodySecondary.copyWith(
                            color: t.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: s.xs),
                  _LoteStatusChip(
                    label: lote['estadoSanitario']?.toString() ?? '—',
                  ),
                  if (isBusy)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    EnterpriseActionsMenuButton<String>(
                      compact: true,
                      items: [
                        const EnterpriseDropdownItem(
                          value: 'editar_precos',
                          label: 'Editar preços do lote',
                          icon: Icons.price_change_outlined,
                        ),
                        const EnterpriseDropdownItem(
                          value: 'editar_info',
                          label: 'Editar informações do lote',
                          icon: Icons.edit_outlined,
                        ),
                        if (LotActionsHelper.canMoveToQuarentena(lote))
                          const EnterpriseDropdownItem(
                            value: 'quarentena',
                            label: 'Mover para Quarentena',
                            icon: Icons.warning_amber_outlined,
                          ),
                        if (LotActionsHelper.canRevertQuarentena(lote))
                          const EnterpriseDropdownItem(
                            value: 'reverter',
                            label: 'Liberar lote',
                            icon: Icons.check_circle_outline,
                          ),
                        const EnterpriseDropdownItem(
                          value: 'historico',
                          label: 'Visualizar histórico do lote',
                          icon: Icons.history,
                        ),
                        const EnterpriseDropdownItem(
                          value: 'recall',
                          label: 'Executar Recall',
                          icon: Icons.report_outlined,
                        ),
                        const EnterpriseDropdownItem(
                          value: 'devolver_fornecedor',
                          label: 'Devolver lote ao fornecedor',
                          icon: Icons.undo,
                        ),
                      ],
                      onSelected: onAction,
                    ),
                ],
              ),
              SizedBox(height: s.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Validade: ${_formatDate(lote['dataValidade'])}',
                      style: theme.textTheme.erpCaption.copyWith(color: color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: s.sm),
                  Text(
                    'Qtd: ${LoteStockUtils.formatDisponivel(lote)}',
                    style: theme.textTheme.erpCaption.copyWith(
                      color: t.textMuted,
                    ),
                  ),
                ],
              ),
              SizedBox(height: s.xxs),
              Text(
                'Dias restantes: ${_daysRemainingLabel(lote['dataValidade'])} • Alerta: ${_alertLabel(lote)}',
                style: theme.textTheme.erpCaption.copyWith(color: t.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: s.xxs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Compra: ${lote['precoCompra']?.toString() ?? '—'}',
                      style: theme.textTheme.erpCaption.copyWith(
                        color: t.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: s.sm),
                  Expanded(
                    child: Text(
                      'Venda: ${lote['precoVenda']?.toString() ?? '—'}',
                      textAlign: TextAlign.end,
                      style: theme.textTheme.erpCaption.copyWith(
                        color: t.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(dynamic value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) return '—';
    return text.length >= 10 ? text.substring(0, 10) : text;
  }

  static int? _daysRemaining(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return null;
    final today = DateTime.now();
    final end = DateTime(parsed.year, parsed.month, parsed.day);
    final start = DateTime(today.year, today.month, today.day);
    return end.difference(start).inDays;
  }

  static String _daysRemainingLabel(dynamic value) {
    final days = _daysRemaining(value);
    if (days == null) return '—';
    if (days < 0) return 'Vencido';
    return '$days';
  }

  static String _secondaryStatus(Map<String, dynamic> lote) {
    final estado = lote['estadoSanitario']?.toString().toUpperCase();
    if (estado == 'EXPIRADO') return 'EXPIRADO';
    if (estado == 'QUARENTENA') return 'BLOQUEADO';
    final days = _daysRemaining(lote['dataValidade']);
    if (days == null) return 'Sem validade';
    if (days < 0) return 'EXPIRADO';
    return 'Expira em $days dias';
  }

  static String _alertLabel(Map<String, dynamic> lote) {
    final indicador = lote['indicadorValidade']?.toString().toUpperCase();
    final estado = lote['estadoSanitario']?.toString().toUpperCase();
    if (estado == 'QUARENTENA') return 'Quarentena';
    if (estado == 'RECALL') return 'Recall';
    if (indicador == 'EXPIRADO' || estado == 'EXPIRADO') return 'Expirado';
    if (indicador == '30_DIAS') return 'Validade crítica';
    if (indicador == '60_DIAS') return 'Próximo da validade';
    return 'Sem alerta';
  }
}

class _LoteStatusChip extends StatelessWidget {
  const _LoteStatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final normalized = label.toUpperCase();
    final color = switch (normalized) {
      'VALIDO' => t.brandGreen,
      'EXPIRADO' => t.posDanger,
      'QUARENTENA' => t.quarantine,
      'RECALL' => t.recall,
      _ => t.textMuted,
    };
    final s = context.spacing;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(RadiusScale.full),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.erpLabel.copyWith(color: color),
      ),
    );
  }
}
