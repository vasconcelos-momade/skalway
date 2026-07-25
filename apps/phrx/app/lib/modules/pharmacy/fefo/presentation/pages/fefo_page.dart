import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/extensions/async_value_extensions.dart';
import '../../../../../core/constants/report_paths.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/responsive/responsive_builder.dart';
import '../../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../../../lots/presentation/widgets/open_lote_details.dart';
import '../providers/fefo_provider.dart';
import '../../../presentation/widgets/pharmacy_report_exports.dart';

class FefoPage extends ConsumerStatefulWidget {
  const FefoPage({super.key});

  @override
  ConsumerState<FefoPage> createState() => _FefoPageState();
}

class _FefoPageState extends ConsumerState<FefoPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _search = TextEditingController();
  var _tabIndex = 0;
  List<Map<String, dynamic>> _accumulatedOverview = [];
  List<Map<String, dynamic>> _accumulatedAudit = [];

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabs.index != _tabIndex) {
      setState(() => _tabIndex = _tabs.index);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(_onTabChanged);
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(fefoViewProvider);
    final controller = ref.read(fefoViewProvider.notifier);
    final state = asyncState.valueOrNull;
    final dash = state?.dashboard;
    final s = context.spacing;
    final t = context.pharmaTokens;

    ref.listen(fefoViewProvider, (prev, next) {
      final previous = prev?.valueOrNull;
      final upcoming = next.valueOrNull;
      if (upcoming == null) return;

      if (previous?.pageOverview != upcoming.pageOverview ||
          previous?.query != upcoming.query ||
          previous?.pageSize != upcoming.pageSize) {
        if (upcoming.pageOverview == 1) {
          _accumulatedOverview = List.of(upcoming.overview);
        } else {
          _accumulatedOverview.addAll(
            upcoming.overview.where(
              (e) => !_accumulatedOverview.any(
                (a) => a['produtoId']?.toString() == e['produtoId']?.toString(),
              ),
            ),
          );
        }
      }

      if (previous?.pageAudit != upcoming.pageAudit ||
          previous?.query != upcoming.query ||
          previous?.situacao != upcoming.situacao ||
          previous?.pageSize != upcoming.pageSize) {
        if (upcoming.pageAudit == 1) {
          _accumulatedAudit = List.of(upcoming.audit);
        } else {
          _accumulatedAudit.addAll(
            upcoming.audit.where(
              (e) => !_accumulatedAudit.any(
                (a) => a['id']?.toString() == e['id']?.toString(),
              ),
            ),
          );
        }
      }
    });

    if (state != null && _search.text != state.query) {
      _search.value = TextEditingValue(
        text: state.query,
        selection: TextSelection.collapsed(offset: state.query.length),
      );
    }

    final reportPath = _tabIndex == 0
        ? ReportPaths.pharmacyFefoOverview
        : ReportPaths.pharmacyFefoAudit;
    final reportQuery = <String, dynamic>{
      if ((state?.query ?? '').isNotEmpty) 'q': state!.query,
      if (_tabIndex == 1 && state?.situacao != null) 'situacao': state!.situacao,
    };
    final kpis = dash == null
        ? null
        : [
            EnterpriseStatCard(
              title: 'Fora FEFO',
              value: '${dash['produtosForaFefo'] ?? 0}',
              icon: Icons.rule_folder_outlined,
            ),
            EnterpriseStatCard(
              title: 'Lotes expirados',
              value: '${dash['lotesExpirados'] ?? 0}',
              icon: Icons.event_busy_outlined,
            ),
            EnterpriseStatCard(
              title: 'Bloqueados',
              value: '${dash['lotesBloqueados'] ?? 0}',
              icon: Icons.block_outlined,
            ),
            EnterpriseStatCard(
              title: 'Alertas',
              value: '${dash['alertasFefo'] ?? 0}',
              icon: Icons.notifications_active_outlined,
            ),
          ];

    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = !constraints.isTabletOrWider;

        return EnterpriseModuleHub(
          mobileKpisHorizontalScroll: true,
          kpis: isMobile ? null : kpis,
          actions: null,
          filters: null,
          child: Column(
            children: [
              if (!isMobile)
                Padding(
                  padding: EdgeInsets.only(bottom: s.md),
                  child: EnterpriseDesktopListToolbar(
                    searchController: _search,
                    searchHint: 'Pesquisar produto ou lote...',
                    isLoading: asyncState.isLoading,
                    onSearchSubmitted: controller.setSearch,
                    hasFilters: state?.situacao != null,
                    onClearFilters: () => controller.setSituacao(null),
                    filterWidgets: [
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String?>(
                          initialValue: state?.situacao,
                          decoration: const InputDecoration(
                            labelText: 'Situação auditoria',
                          ),
                          items: const [
                            DropdownMenuItem<String?>(value: null, child: Text('Todas')),
                            DropdownMenuItem<String?>(value: 'CONFORME', child: Text('Conforme')),
                            DropdownMenuItem<String?>(value: 'VIOLACAO', child: Text('Violação')),
                            DropdownMenuItem<String?>(value: 'EXPIRADO', child: Text('Expirado')),
                            DropdownMenuItem<String?>(value: 'QUARENTENA', child: Text('Quarentena')),
                          ],
                          onChanged: asyncState.isLoading ? null : controller.setSituacao,
                        ),
                      ),
                    ],
                    trailingActions: [
                      ...pharmacyReportActions(
                        ref: ref,
                        enabled: !asyncState.isLoading,
                        path: reportPath,
                        queryParameters: reportQuery,
                      ),
                      IconButton(
                        onPressed: () => controller.refresh(force: true),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                ),
              TabBar(
                controller: _tabs,
                tabs: const [
                  Tab(text: 'Visão geral'),
                  Tab(text: 'Auditoria'),
                ],
              ),
              Expanded(
                child: isMobile
                    ? TabBarView(
                        controller: _tabs,
                        children: [
                          _buildMobileTab(
                            context: context,
                            ref: ref,
                            kpis: kpis,
                            items: _accumulatedOverview,
                            hasMore: state?.hasMoreOverview ?? false,
                            isLoading: asyncState.isLoading,
                            reportPath: ReportPaths.pharmacyFefoOverview,
                            reportQuery: reportQuery,
                            totalCount: state?.totalCountOverview,
                            onLoadMore: () =>
                                controller.goToPageOverview((state?.pageOverview ?? 1) + 1),
                            onRefresh: () => controller.refresh(force: true),
                            onSearch: controller.setSearch,
                            cardBuilder: _overviewMobileCard,
                          ),
                          _buildMobileTab(
                            context: context,
                            ref: ref,
                            kpis: kpis,
                            items: _accumulatedAudit,
                            hasMore: state?.hasMoreAudit ?? false,
                            isLoading: asyncState.isLoading,
                            reportPath: ReportPaths.pharmacyFefoAudit,
                            reportQuery: reportQuery,
                            totalCount: state?.totalCountAudit,
                            onLoadMore: () =>
                                controller.goToPageAudit((state?.pageAudit ?? 1) + 1),
                            onRefresh: () => controller.refresh(force: true),
                            onSearch: controller.setSearch,
                            onOpenFilters: () => _openAuditFilters(context, controller, state),
                            hasFilters: state?.situacao != null,
                            onClearFilters: () => controller.setSituacao(null),
                            cardBuilder: _auditMobileCard,
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          if (asyncState.isLoading) const LinearProgressIndicator(),
                          if (asyncState.hasError)
                            Padding(
                              padding: EdgeInsets.only(bottom: s.sm),
                              child: Text(
                                asyncState.error.toString(),
                                style: Theme.of(context).textTheme.erpBody.copyWith(color: t.posDanger),
                              ),
                            ),
                          Expanded(
                            child: TabBarView(
                              controller: _tabs,
                              children: [
                                _overviewTable(state),
                                _auditTable(state),
                              ],
                            ),
                          ),
                          if (_tabIndex == 0 && state?.totalCountOverview != null)
                            EnterprisePagination(
                              page: state?.pageOverview ?? 1,
                              pageSize: state?.pageSize ?? 20,
                              totalCount: state!.totalCountOverview!,
                              itemLabel: 'registos',
                              isBusy: asyncState.isLoading,
                              onPageChanged: controller.goToPageOverview,
                              onPageSizeChanged: controller.setPageSize,
                            ),
                          if (_tabIndex == 1 && state?.totalCountAudit != null)
                            EnterprisePagination(
                              page: state?.pageAudit ?? 1,
                              pageSize: state?.pageSize ?? 20,
                              totalCount: state!.totalCountAudit!,
                              itemLabel: 'registos',
                              isBusy: asyncState.isLoading,
                              onPageChanged: controller.goToPageAudit,
                              onPageSizeChanged: controller.setPageSize,
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileTab({
    required BuildContext context,
    required WidgetRef ref,
    required List<EnterpriseStatCard>? kpis,
    required List<Map<String, dynamic>> items,
    required bool hasMore,
    required bool isLoading,
    required String reportPath,
    required Map<String, dynamic> reportQuery,
    required int? totalCount,
    required VoidCallback onLoadMore,
    required VoidCallback onRefresh,
    required ValueChanged<String> onSearch,
    required Widget Function(Map<String, dynamic>) cardBuilder,
    VoidCallback? onOpenFilters,
    bool hasFilters = false,
    VoidCallback? onClearFilters,
  }) {
    return EnterpriseMobileScrollList(
      kpis: kpis?.cast<Widget>(),
      stickyHeader: EnterpriseMobileToolbar(
        searchController: _search,
        searchHint: 'Produto ou nº lote...',
        enabled: !isLoading,
        isLoading: isLoading,
        hasFilters: hasFilters,
        showFiltersButton: onOpenFilters != null,
        onSearchSubmitted: onSearch,
        onOpenFilters: onOpenFilters ?? () {},
            onClearFilters:
            onClearFilters != null ? () async => onClearFilters() : null,
        onRefresh: onRefresh,
        reportAction: pharmacyReportActions(
          ref: ref,
          enabled: !isLoading,
          path: reportPath,
          queryParameters: reportQuery,
          expandChild: true,
        ).single,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => cardBuilder(items[index]),
      hasMore: hasMore,
      isLoading: isLoading,
      onLoadMore: onLoadMore,
      emptyMessage: 'Nenhum registo encontrado',
      totalCount: totalCount,
      totalCountLabel: totalCount != null ? 'Total: $totalCount registo(s)' : null,
    );
  }

  Widget _overviewTable(FefoViewState? state) {
    return EnterpriseDataTable(
      adaptive: false,
      showCheckboxColumn: false,
      columns: const [
        DataColumn(label: Text('PRODUTO')),
        DataColumn(label: Text('LOTE FEFO')),
        DataColumn(label: Text('VALIDADE')),
        DataColumn(label: Text('STOCK')),
        DataColumn(label: Text('SITUAÇÃO')),
        DataColumn(label: Text('ALERTA')),
      ],
      rowCount: state?.overview.length ?? 0,
      rowBuilder: (context, index) {
        final item = state!.overview[index];
        final lote = item['loteRecomendado'] as Map<String, dynamic>?;
        final loteId = lote?['id']?.toString() ?? item['loteId']?.toString();
        return DataRow(
          onSelectChanged: loteId != null && loteId.isNotEmpty
              ? (_) => _openLotDrawer(loteId)
              : null,
          cells: [
            DataCell(Text(item['produtoNomeComercial']?.toString() ?? item['produtoNome']?.toString() ?? '—')),
            DataCell(Text(lote?['numeroLote']?.toString() ?? '—')),
            DataCell(Text(lote?['dataValidade']?.toString().substring(0, 10) ?? '—')),
            DataCell(Text(lote?['stock']?.toString() ?? '0')),
            DataCell(Text(item['situacao']?.toString() ?? '—')),
            DataCell(Text(_alertLabel(item['situacao']?.toString()))),
          ],
        );
      },
    );
  }

  Widget _auditTable(FefoViewState? state) {
    return EnterpriseDataTable(
      adaptive: false,
      showCheckboxColumn: false,
      columns: const [
        DataColumn(label: Text('PRODUTO')),
        DataColumn(label: Text('LOTE USADO')),
        DataColumn(label: Text('LOTE CORRECTO')),
        DataColumn(label: Text('UTILIZADOR')),
        DataColumn(label: Text('DATA')),
        DataColumn(label: Text('SITUAÇÃO')),
        DataColumn(label: Text('MOTIVO')),
      ],
      rowCount: state?.audit.length ?? 0,
      rowBuilder: (context, index) {
        final item = state!.audit[index];
        final usado = item['loteUtilizado'] as Map<String, dynamic>?;
        final correto = item['loteCorreto'] as Map<String, dynamic>?;
        final user = item['utilizador'] as Map<String, dynamic>?;
        final loteId = usado?['id']?.toString() ?? correto?['id']?.toString();
        return DataRow(
          onSelectChanged: loteId != null && loteId.isNotEmpty
              ? (_) => _openLotDrawer(loteId)
              : null,
          cells: [
            DataCell(Text(item['produtoNomeComercial']?.toString() ?? item['produtoNome']?.toString() ?? '—')),
            DataCell(Text(usado?['numeroLote']?.toString() ?? '—')),
            DataCell(Text(correto?['numeroLote']?.toString() ?? '—')),
            DataCell(Text(user?['nome']?.toString() ?? '—')),
            DataCell(Text(item['data']?.toString().substring(0, 10) ?? '—')),
            DataCell(Text(item['situacao']?.toString() ?? '—')),
            DataCell(Text(item['motivo']?.toString() ?? '—')),
          ],
        );
      },
    );
  }

  void _openAuditFilters(
    BuildContext context,
    FefoViewController controller,
    FefoViewState? state,
  ) {
    showEnterpriseFiltersSheet(
      context: context,
      child: _FefoAuditFiltersSheet(
        initialSituacao: state?.situacao,
        onApply: controller.setSituacao,
      ),
    );
  }

  Widget _overviewMobileCard(Map<String, dynamic> item) {
    final lote = item['loteRecomendado'] as Map<String, dynamic>?;
    final loteId = lote?['id']?.toString() ?? item['loteId']?.toString();
    return EnterpriseListCard(
      leading: Icons.inventory_2_outlined,
      title: item['produtoNomeComercial']?.toString() ?? item['produtoNome']?.toString() ?? '—',
      subtitle: 'Lote FEFO: ${lote?['numeroLote']?.toString() ?? '—'}',
      chip: EnterpriseStatusChip(label: item['situacao']?.toString() ?? '—'),
      metadata: [
        EnterpriseListCardMeta(
          label:
              'Validade: ${lote?['dataValidade']?.toString().substring(0, 10) ?? '—'} · Stock: ${lote?['stock'] ?? 0}',
        ),
        EnterpriseListCardMeta(label: _alertLabel(item['situacao']?.toString())),
      ],
      onTap: loteId != null && loteId.isNotEmpty ? () => _openLotDrawer(loteId) : null,
    );
  }

  Widget _auditMobileCard(Map<String, dynamic> item) {
    final usado = item['loteUtilizado'] as Map<String, dynamic>?;
    final correto = item['loteCorreto'] as Map<String, dynamic>?;
    final user = item['utilizador'] as Map<String, dynamic>?;
    final loteId = usado?['id']?.toString() ?? correto?['id']?.toString();
    return EnterpriseListCard(
      leading: Icons.rule_folder_outlined,
      title: item['produtoNomeComercial']?.toString() ?? item['produtoNome']?.toString() ?? '—',
      subtitle: '${usado?['numeroLote'] ?? '—'} → ${correto?['numeroLote'] ?? '—'}',
      chip: EnterpriseStatusChip(label: item['situacao']?.toString() ?? '—'),
      metadata: [
        EnterpriseListCardMeta(
          label: '${user?['nome'] ?? '—'} · ${item['data']?.toString().substring(0, 10) ?? '—'}',
        ),
        EnterpriseListCardMeta(label: item['motivo']?.toString() ?? '—'),
      ],
      onTap: loteId != null && loteId.isNotEmpty ? () => _openLotDrawer(loteId) : null,
    );
  }

  Future<void> _openLotDrawer(String loteId) => openLoteDetails(context, loteId);

  String _alertLabel(String? situacao) {
    switch (situacao) {
      case 'VIOLACAO_FEFO':
        return 'Violação operacional';
      case 'SEM_LOTE_FEFO':
        return 'Sem lote elegível';
      case 'CONFORME_FEFO':
      default:
        return 'Conforme';
    }
  }
}

class _FefoAuditFiltersSheet extends StatelessWidget {
  const _FefoAuditFiltersSheet({
    required this.initialSituacao,
    required this.onApply,
  });

  final String? initialSituacao;
  final ValueChanged<String?> onApply;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    var situacao = initialSituacao;

    return StatefulBuilder(
      builder: (context, setState) {
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
              Text(
                'Situação auditoria',
                style: Theme.of(context).textTheme.erpSectionTitle,
              ),
              SizedBox(height: s.md),
              DropdownButtonFormField<String?>(
                initialValue: situacao,
                decoration: const InputDecoration(
                  labelText: 'Situação',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem<String?>(value: null, child: Text('Todas')),
                  DropdownMenuItem<String?>(value: 'CONFORME', child: Text('Conforme')),
                  DropdownMenuItem<String?>(value: 'VIOLACAO', child: Text('Violação')),
                  DropdownMenuItem<String?>(value: 'EXPIRADO', child: Text('Expirado')),
                  DropdownMenuItem<String?>(value: 'QUARENTENA', child: Text('Quarentena')),
                ],
                onChanged: (value) => setState(() => situacao = value),
              ),
              SizedBox(height: s.lg),
              FilledButton(
                onPressed: () {
                  onApply(situacao);
                  Navigator.of(context).pop();
                },
                child: const Text('Aplicar'),
              ),
            ],
          ),
        );
      },
    );
  }
}
