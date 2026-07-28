import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../core/utils/lote_stock_utils.dart';
import '../../../../../shared/responsive/responsive_builder.dart';
import '../../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../stock/presentation/widgets/movimentacoes_pagination.dart';
import '../../../regulatory/data/datasources/regulatory_remote_datasource.dart';
import '../../../lots/presentation/widgets/lot_actions_helper.dart';
import '../../../../../shared/refresh/page_refresh.dart';

class RegulatoryPage extends ConsumerStatefulWidget {
  const RegulatoryPage({super.key});

  @override
  ConsumerState<RegulatoryPage> createState() => _RegulatoryPageState();
}

class _RegulatoryPageState extends ConsumerState<RegulatoryPage> {
  late final TextEditingController _searchController;
  Timer? _refreshTimer;

  bool _loadingSanitario = true;
  String? _sanitarioError;
  Map<String, dynamic>? _dashboard;
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _accumulatedSanitario = <Map<String, dynamic>>[];
  int _page = 1;
  int _pageSize = PaginationDefaults.pageSize;
  bool _hasMore = false;
  int _total = 0;
  String _search = '';
  String? _estado;
  String? _alertaTipo;

  RegulatoryRemoteDataSource get _ds =>
      ref.read(regulatoryRemoteDataSourceProvider);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadSanitario();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _loadSanitario(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSanitario({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loadingSanitario = true;
        _sanitarioError = null;
      });
    }
    try {
      final results = await Future.wait([
        _ds.sanitarioDashboard(search: _search.isEmpty ? null : _search),
        _ds.listSanitario(
          search: _search.isEmpty ? null : _search,
          estado: _estado,
          alertaTipo: _alertaTipo,
          page: _page,
          pageSize: _pageSize,
        ),
      ]);
      final page = results[1] as dynamic;
      if (!mounted) return;
      setState(() {
        _dashboard = results[0] as Map<String, dynamic>;
        _items = page.items.cast<Map<String, dynamic>>();
        if (_page == 1) {
          _accumulatedSanitario = List.of(_items);
        } else {
          _accumulatedSanitario.addAll(
            _items.where(
              (e) => !_accumulatedSanitario.any(
                (a) => a['id']?.toString() == e['id']?.toString(),
              ),
            ),
          );
        }
        _page = page.page as int;
        _pageSize = page.pageSize as int;
        _hasMore = page.hasMore as bool;
        _total = (page.totalCount as int?) ?? _items.length;
        _loadingSanitario = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingSanitario = false;
        _sanitarioError = error.toString();
      });
    }
  }

  Future<void> _openHistory(String loteId) async {
    await LotActionsHelper.showHistory(context, ref, loteId);
  }

  @override
  Widget build(BuildContext context) {
    final dash = _dashboard?['kpis'] as Map<String, dynamic>?;
    final kpis = dash == null
        ? null
        : [
            EnterpriseStatCard(
              title: 'Expirados',
              value: '${dash['expirados'] ?? 0}',
              icon: Icons.warning_amber_outlined,
            ),
            EnterpriseStatCard(
              title: 'Próx. validade',
              value: '${dash['proximosValidade'] ?? 0}',
              icon: Icons.schedule_outlined,
            ),
            EnterpriseStatCard(
              title: 'Recall',
              value: '${dash['recall'] ?? 0}',
              icon: Icons.report_problem_outlined,
            ),
            EnterpriseStatCard(
              title: 'Quarentena',
              value: '${dash['quarentena'] ?? 0}',
              icon: Icons.health_and_safety_outlined,
            ),
            EnterpriseStatCard(
              title: 'Incinerações',
              value: '${dash['incineracoes'] ?? 0}',
              icon: Icons.local_fire_department_outlined,
            ),
            EnterpriseStatCard(
              title: 'Alertas',
              value: '${dash['alertasSanitarios'] ?? 0}',
              icon: Icons.notifications_active_outlined,
            ),
          ];

    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = !constraints.isTabletOrWider;

        return PageRefreshBinder(
      onRefresh: () async { await _loadSanitario(); },
      child: EnterpriseModuleHub(
          title: 'Sanitário / Alertas',
          subtitle:
              'Validade, recall, quarentena, incineração e stock crítico.',
          tag: 'Regulatório',
          mobileKpisHorizontalScroll: true,
          actions: isMobile
              ? null
              : [
                ],
          kpis: isMobile ? null : kpis,
          filters: isMobile ? null : _buildSanitarioFilters(),
          child: _buildSanitarioBody(context, isMobile: isMobile, kpis: kpis),
        ),
    );
      },
    );
  }

  Widget _buildSanitarioFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Produto, lote, barcode...',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (value) {
              setState(() {
                _search = value.trim();
                _page = 1;
              });
              _loadSanitario();
            },
          ),
        ),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String?>(
            initialValue: _estado,
            decoration: const InputDecoration(
              labelText: 'Estado',
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todos')),
              DropdownMenuItem(value: 'EXPIRADO', child: Text('Expirado')),
              DropdownMenuItem(value: 'RECALL', child: Text('Recall')),
              DropdownMenuItem(value: 'QUARENTENA', child: Text('Quarentena')),
              DropdownMenuItem(value: 'BLOQUEADO', child: Text('Bloqueado')),
              DropdownMenuItem(value: 'CRITICO', child: Text('Crítico')),
            ],
            onChanged: (value) {
              setState(() {
                _estado = value;
                _page = 1;
              });
              _loadSanitario();
            },
          ),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String?>(
            initialValue: _alertaTipo,
            decoration: const InputDecoration(
              labelText: 'Tipo de alerta',
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todos')),
              DropdownMenuItem(
                value: 'LOTE_EXPIRADO',
                child: Text('Lote expirado'),
              ),
              DropdownMenuItem(
                value: 'LOTE_A_EXPIRAR',
                child: Text('Lote a expirar'),
              ),
              DropdownMenuItem(
                value: 'ESTOQUE_BAIXO',
                child: Text('Stock baixo'),
              ),
              DropdownMenuItem(
                value: 'PRODUTO_ESGOTADO',
                child: Text('Esgotado'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _alertaTipo = value;
                _page = 1;
              });
              _loadSanitario();
            },
          ),
        ),
      ],
    );
  }

  void _openSanitarioFilters(BuildContext context) {
    showEnterpriseFiltersSheet(
      context: context,
      child: StatefulBuilder(
        builder: (context, setModalState) {
          var estado = _estado;
          var alertaTipo = _alertaTipo;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Filtros sanitários',
                  style: Theme.of(context).textTheme.erpSectionTitle,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String?>(
                  initialValue: estado,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(
                      value: 'EXPIRADO',
                      child: Text('Expirado'),
                    ),
                    DropdownMenuItem(value: 'RECALL', child: Text('Recall')),
                    DropdownMenuItem(
                      value: 'QUARENTENA',
                      child: Text('Quarentena'),
                    ),
                    DropdownMenuItem(
                      value: 'BLOQUEADO',
                      child: Text('Bloqueado'),
                    ),
                    DropdownMenuItem(value: 'CRITICO', child: Text('Crítico')),
                  ],
                  onChanged: (value) => setModalState(() => estado = value),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String?>(
                  initialValue: alertaTipo,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de alerta',
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(
                      value: 'LOTE_EXPIRADO',
                      child: Text('Lote expirado'),
                    ),
                    DropdownMenuItem(
                      value: 'LOTE_A_EXPIRAR',
                      child: Text('Lote a expirar'),
                    ),
                    DropdownMenuItem(
                      value: 'ESTOQUE_BAIXO',
                      child: Text('Stock baixo'),
                    ),
                    DropdownMenuItem(
                      value: 'PRODUTO_ESGOTADO',
                      child: Text('Esgotado'),
                    ),
                  ],
                  onChanged: (value) => setModalState(() => alertaTipo = value),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _estado = estado;
                      _alertaTipo = alertaTipo;
                      _page = 1;
                    });
                    Navigator.of(context).pop();
                    _loadSanitario();
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSanitarioBody(
    BuildContext context, {
    bool isMobile = false,
    List<EnterpriseStatCard>? kpis,
  }) {
    final t = context.pharmaTokens;

    if (isMobile) {
      return EnterpriseMobileScrollList(
        kpis: kpis,
        stickyHeader: EnterpriseMobileToolbar(
          searchController: _searchController,
          searchHint: 'Produto, lote, barcode...',
          enabled: !_loadingSanitario,
          isLoading: _loadingSanitario,
          hasFilters: _estado != null || _alertaTipo != null,
          onSearchSubmitted: (value) {
            setState(() {
              _search = value.trim();
              _page = 1;
            });
            _loadSanitario();
          },
          onOpenFilters: () => _openSanitarioFilters(context),
          onClearFilters: () async {
            setState(() {
              _estado = null;
              _alertaTipo = null;
              _page = 1;
            });
            await _loadSanitario();
          },
          onRefresh: _loadSanitario,
        ),
        itemCount: _accumulatedSanitario.length,
        itemBuilder: (context, index) {
          final item = _accumulatedSanitario[index];
          return EnterpriseListCard(
            leading: Icons.health_and_safety_outlined,
            title: item['produto']?['nome']?.toString() ?? '—',
            subtitle: 'Lote: ${item['numeroLote']?.toString() ?? '—'}',
            chip: _SanitaryBadge(label: item['status']?.toString()),
            metadata: [
              EnterpriseListCardMeta(
                label:
                    'Validade: ${item['dataValidade']?.toString().substring(0, 10) ?? '—'}',
              ),
              EnterpriseListCardMeta(
                label:
                    '${item['latestAlert']?['tipo']?.toString() ?? '—'} · Stock: ${LoteStockUtils.formatDisponivel(item)}',
              ),
            ],
            onTap: () => _openHistory(item['id'].toString()),
          );
        },
        hasMore: _hasMore,
        isLoading: _loadingSanitario,
        onLoadMore: () {
          setState(() => _page += 1);
          _loadSanitario();
        },
        emptyMessage: 'Sem resultados para os filtros selecionados.',
        totalCount: _total,
        totalCountLabel: 'Total: $_total lote(s)',
      );
    }

    return Column(
      children: [
        if (_loadingSanitario) const LinearProgressIndicator(),
        if (_sanitarioError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              _sanitarioError!,
              style: Theme.of(
                context,
              ).textTheme.erpBody.copyWith(color: t.posDanger),
            ),
          ),
        Expanded(
          child: _items.isEmpty && !_loadingSanitario
              ? const Center(
                  child: Text('Sem resultados para os filtros selecionados.'),
                )
              : EnterpriseDataTable(
                  adaptive: false,
                  showCheckboxColumn: false,
                  columns: const [
                    DataColumn(label: Text('PRODUTO')),
                    DataColumn(label: Text('LOTE')),
                    DataColumn(label: Text('VALIDADE')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('ALERTA')),
                    DataColumn(label: Text('STOCK')),
                  ],
                  rowCount: _items.length,
                  rowBuilder: (context, index) {
                    final item = _items[index];
                    return DataRow(
                      onSelectChanged: (_) =>
                          _openHistory(item['id'].toString()),
                      cells: [
                        DataCell(
                          Text(item['produto']?['nome']?.toString() ?? '—'),
                        ),
                        DataCell(Text(item['numeroLote']?.toString() ?? '—')),
                        DataCell(
                          Text(
                            item['dataValidade']?.toString().substring(0, 10) ??
                                '—',
                          ),
                        ),
                        DataCell(
                          _SanitaryBadge(label: item['status']?.toString()),
                        ),
                        DataCell(
                          Text(item['latestAlert']?['tipo']?.toString() ?? '—'),
                        ),
                        DataCell(Text(LoteStockUtils.formatDisponivel(item))),
                      ],
                    );
                  },
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        MovimentacoesPagination(
          page: _page,
          pageSize: _pageSize,
          hasMore: _hasMore,
          isBusy: _loadingSanitario,
          totalCount: _total,
          itemsOnPage: _items.length,
          itemLabel: 'lotes',
          onPageChanged: (nextPage) {
            setState(() => _page = nextPage);
            _loadSanitario();
          },
          onPageSizeChanged: (value) {
            setState(() {
              _pageSize = value;
              _page = 1;
            });
            _loadSanitario();
          },
        ),
        Text(
          'Total: $_total lote(s)',
          style: Theme.of(
            context,
          ).textTheme.erpCaption.copyWith(color: t.textMuted),
        ),
      ],
    );
  }
}

class _SanitaryBadge extends StatelessWidget {
  const _SanitaryBadge({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final value = label ?? '—';
    final color = switch (value) {
      'EXPIRADO' => t.posDanger,
      'RECALL' => Colors.deepOrange,
      'QUARENTENA' => t.posWarning,
      'BLOQUEADO' => Colors.amber.shade800,
      'CRITICO' => Colors.redAccent,
      _ => t.brandGreen,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.erpLabel.copyWith(color: color),
      ),
    );
  }
}
