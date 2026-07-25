import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../../../../../shared/responsive/responsive_builder.dart';
import '../../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../stock/presentation/widgets/movimentacoes_pagination.dart';
import '../../../regulatory/data/datasources/regulatory_remote_datasource.dart';

class PsychotropicsBookPage extends ConsumerStatefulWidget {
  const PsychotropicsBookPage({super.key});

  @override
  ConsumerState<PsychotropicsBookPage> createState() =>
      _PsychotropicsBookPageState();
}

class _PsychotropicsBookPageState extends ConsumerState<PsychotropicsBookPage> {
  late final TextEditingController _searchController;
  Timer? _refreshTimer;

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _dashboard;
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  int _page = 1;
  int _pageSize = PaginationDefaults.pageSize;
  bool _hasMore = false;
  int _total = 0;
  String _search = '';
  String? _tipoMovimento;
  final String _sortBy = 'createdAt';
  final String _sortDir = 'desc';

  RegulatoryRemoteDataSource get _ds =>
      ref.read(regulatoryRemoteDataSourceProvider);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _load();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        _ds.livroPsicotropicosDashboard(
          search: _search.isEmpty ? null : _search,
          tipoMovimento: _tipoMovimento,
        ),
        _ds.listLivroPsicotropicos(
          search: _search.isEmpty ? null : _search,
          tipoMovimento: _tipoMovimento,
          sortBy: _sortBy,
          sortDir: _sortDir,
          page: _page,
          pageSize: _pageSize,
        ),
      ]);
      final page = results[1] as dynamic;
      if (!mounted) return;
      setState(() {
        _dashboard = results[0] as Map<String, dynamic>;
        _items = page.items.cast<Map<String, dynamic>>();
        _page = page.page as int;
        _pageSize = page.pageSize as int;
        _hasMore = page.hasMore as bool;
        _total = (page.totalCount as int?) ?? _items.length;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _openDetail(String id) async {
    await AdaptiveNavigator.openPanel<void>(
      context: context,
      sideSheetWidth: 860,
      builder: (panelContext) => SizedBox(
        width: 860,
        height: 640,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _ds.getLivroPsicotropico(id),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            final data = snapshot.data ?? const <String, dynamic>{};
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Movimento ${data['numeroDocumento'] ?? data['id']}',
                          style: Theme.of(context).textTheme.erpCardTitle,
                        ),
                      ),
                      IconButton(
                        onPressed: () => AdaptiveNavigator.close(panelContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _PsychInfo(
                            label: 'Produto',
                            value: data['produto']?['nome']?.toString() ?? '—',
                          ),
                          _PsychInfo(
                            label: 'Movimento',
                            value: data['tipoMovimento']?.toString() ?? '—',
                          ),
                          _PsychInfo(
                            label: 'Quantidade',
                            value: '${data['quantidade'] ?? 0}',
                          ),
                          _PsychInfo(
                            label: 'Saldo',
                            value: '${data['saldoAtual'] ?? 0}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Auditoria',
                        style: Theme.of(context).textTheme.erpBodyStrong,
                      ),
                      const SizedBox(height: 8),
                      ...(data['auditLogs'] as List<dynamic>? ?? const []).map(
                        (item) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(item['action']?.toString() ?? '—'),
                          subtitle: Text(item['createdAt']?.toString() ?? '—'),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final dash = _dashboard?['kpis'] as Map<String, dynamic>?;
    final t = context.pharmaTokens;
    final kpiCards = dash == null
        ? <EnterpriseStatCard>[]
        : [
            EnterpriseStatCard(
              title: 'Movimentos',
              value: '${dash['totalMovimentos'] ?? 0}',
              icon: Icons.menu_book_outlined,
              density: StatCardDensity.compact,
            ),
            EnterpriseStatCard(
              title: 'Entradas',
              value: '${dash['entradas'] ?? 0}',
              icon: Icons.call_received_outlined,
              density: StatCardDensity.compact,
            ),
            EnterpriseStatCard(
              title: 'Saídas',
              value: '${dash['saidas'] ?? 0}',
              icon: Icons.call_made_outlined,
              density: StatCardDensity.compact,
            ),
            EnterpriseStatCard(
              title: 'Produtos',
              value: '${dash['produtosMonitorados'] ?? 0}',
              icon: Icons.medication_outlined,
              density: StatCardDensity.compact,
            ),
          ];

    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = !constraints.isTabletOrWider;

        return EnterpriseModuleHub(
          title: 'Livro de Psicotrópicos',
          subtitle:
              'Livro oficial de entradas e saídas com saldos, conformidade e auditoria regulatória.',
          tag: 'Regulatório',
          mobileKpisHorizontalScroll: true,
          actions: isMobile
              ? null
              : [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
          kpis: isMobile ? null : (kpiCards.isEmpty ? null : kpiCards),
          filters: isMobile ? null : _buildFilters(),
          child: isMobile
              ? EnterpriseMobileScrollList(
                  kpis: kpiCards.isEmpty ? null : kpiCards,
                  errorText: _error,
                  stickyHeader: EnterpriseMobileToolbar(
                    searchController: _searchController,
                    searchHint: 'Documento, produto, lote...',
                    enabled: !_loading,
                    isLoading: _loading,
                    hasFilters: _tipoMovimento != null || _search.isNotEmpty,
                    onSearchSubmitted: (value) {
                      setState(() {
                        _search = value.trim();
                        _page = 1;
                      });
                      _load();
                    },
                    onOpenFilters: () => _openMobileFilters(context),
                    onClearFilters: () async {
                      setState(() {
                        _search = '';
                        _tipoMovimento = null;
                        _page = 1;
                        _searchController.clear();
                      });
                      await _load();
                    },
                    onRefresh: _load,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return EnterpriseListCard(
                      leading: Icons.menu_book_outlined,
                      title: item['produto']?['nome']?.toString() ?? '—',
                      subtitle: item['numeroDocumento']?.toString() ?? '—',
                      chip: EnterpriseStatusChip(
                        label: item['tipoMovimento']?.toString() ?? '—',
                      ),
                      metadata: [
                        EnterpriseListCardMeta(
                          label:
                              'Lote: ${item['lote']?['numeroLote']?.toString() ?? '—'}',
                        ),
                        EnterpriseListCardMeta(
                          label:
                              'Qtd: ${item['quantidade'] ?? 0} · Saldo: ${item['saldoAtual'] ?? 0}',
                          emphasized: true,
                        ),
                      ],
                      onTap: () => _openDetail(item['id'].toString()),
                    );
                  },
                  hasMore: false,
                  isLoading: _loading,
                  emptyMessage: 'Sem resultados para os filtros selecionados.',
                  totalCount: _total,
                  totalCountLabel: 'movimentos',
                )
              : Column(
                  children: [
                    if (_loading) const LinearProgressIndicator(),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(
                          _error!,
                          style: Theme.of(context)
                              .textTheme
                              .erpBody
                              .copyWith(color: t.posDanger),
                        ),
                      ),
                    Expanded(
                      child: _items.isEmpty && !_loading
                          ? const Center(
                              child: Text(
                                'Sem resultados para os filtros selecionados.',
                              ),
                            )
                          : EnterpriseDataTable(
                              columns: const [
                                DataColumn(label: Text('DOCUMENTO')),
                                DataColumn(label: Text('PRODUTO')),
                                DataColumn(label: Text('LOTE')),
                                DataColumn(label: Text('MOVIMENTO')),
                                DataColumn(label: Text('QTD')),
                                DataColumn(label: Text('SALDO')),
                              ],
                              rowCount: _items.length,
                              rowBuilder: (context, index) {
                                final item = _items[index];
                                return DataRow(
                                  onSelectChanged: (_) =>
                                      _openDetail(item['id'].toString()),
                                  cells: [
                                    DataCell(
                                      Text(
                                        item['numeroDocumento']?.toString() ??
                                            '—',
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        item['produto']?['nome']?.toString() ??
                                            '—',
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        item['lote']?['numeroLote']
                                                ?.toString() ??
                                            '—',
                                      ),
                                    ),
                                    DataCell(
                                      _PsychBadge(
                                        label: item['tipoMovimento']?.toString(),
                                      ),
                                    ),
                                    DataCell(Text('${item['quantidade'] ?? 0}')),
                                    DataCell(Text('${item['saldoAtual'] ?? 0}')),
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
                      isBusy: _loading,
                      totalCount: _total,
                      itemsOnPage: _items.length,
                      onPageChanged: (nextPage) {
                        setState(() => _page = nextPage);
                        _load();
                      },
                      onPageSizeChanged: (value) {
                        setState(() {
                          _pageSize = value;
                          _page = 1;
                        });
                        _load();
                      },
                    ),
                    Text(
                      'Total: $_total movimento(s)',
                      style: Theme.of(context)
                          .textTheme
                          .erpCaption
                          .copyWith(color: t.textMuted),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Documento, produto, lote...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              setState(() {
                _search = value.trim();
                _page = 1;
              });
              _load();
            },
          ),
        ),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String?>(
            initialValue: _tipoMovimento,
            decoration: const InputDecoration(
              labelText: 'Movimento',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todos')),
              DropdownMenuItem(value: 'ENTRADA', child: Text('Entrada')),
              DropdownMenuItem(value: 'SAIDA', child: Text('Saída')),
              DropdownMenuItem(
                value: 'IMPORTACAO',
                child: Text('Importação'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _tipoMovimento = value;
                _page = 1;
              });
              _load();
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openMobileFilters(BuildContext context) async {
    String? tipo = _tipoMovimento;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String?>(
                    initialValue: tipo,
                    decoration: const InputDecoration(
                      labelText: 'Movimento',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Todos')),
                      DropdownMenuItem(value: 'ENTRADA', child: Text('Entrada')),
                      DropdownMenuItem(value: 'SAIDA', child: Text('Saída')),
                      DropdownMenuItem(
                        value: 'IMPORTACAO',
                        child: Text('Importação'),
                      ),
                    ],
                    onChanged: (value) => setModalState(() => tipo = value),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _tipoMovimento = tipo;
                        _page = 1;
                      });
                      Navigator.of(context).pop();
                      _load();
                    },
                    child: const Text('Aplicar'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PsychInfo extends StatelessWidget {
  const _PsychInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.erpCaption.copyWith(color: t.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.erpLabel.copyWith(color: t.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _PsychBadge extends StatelessWidget {
  const _PsychBadge({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final value = label ?? '—';
    final color = switch (value) {
      'ENTRADA' || 'IMPORTACAO' => t.posInfo,
      'SAIDA' => t.posDanger,
      _ => t.textMuted,
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
