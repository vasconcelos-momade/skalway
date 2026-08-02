import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/cards/enterprise_stat_card.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../stock/presentation/widgets/movimentacoes_pagination.dart';
import '../../../pharmacy/regulatory/data/datasources/regulatory_remote_datasource.dart';
import '../../../../shared/refresh/page_refresh.dart';

class AuditPsychotropicsPage extends ConsumerStatefulWidget {
  const AuditPsychotropicsPage({super.key});

  @override
  ConsumerState<AuditPsychotropicsPage> createState() =>
      _AuditPsychotropicsPageState();
}

class _AuditPsychotropicsPageState
    extends ConsumerState<AuditPsychotropicsPage> {
  late final TextEditingController _searchController;
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm');

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _dashboard;
  List<Map<String, dynamic>> _items = const [];
  List<Map<String, dynamic>> _accumulatedItems = const [];
  int _page = 1;
  int _pageSize = 20;
  bool _hasMore = false;
  String _search = '';

  RegulatoryRemoteDataSource get _ds =>
      ref.read(regulatoryRemoteDataSourceProvider);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
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
        ),
        _ds.listLivroPsicotropicos(
          search: _search.isEmpty ? null : _search,
          page: _page,
          pageSize: _pageSize,
        ),
      ]);
      final page = results[1] as dynamic;
      if (!mounted) return;
      final items = page.items.cast<Map<String, dynamic>>() as List<Map<String, dynamic>>;
      setState(() {
        _dashboard = results[0] as Map<String, dynamic>;
        _items = items;
        if (_page == 1) {
          _accumulatedItems = List.of(items);
        } else {
          _accumulatedItems = [
            ..._accumulatedItems,
            ...items.where(
              (e) => !_accumulatedItems.any((a) => a['id'] == e['id']),
            ),
          ];
        }
        _page = page.page as int;
        _pageSize = page.pageSize as int;
        _hasMore = page.hasMore as bool;
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

  void _onSearchSubmitted(String value) {
    _search = value.trim();
    _page = 1;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final dash =
        _dashboard?['kpis'] as Map<String, dynamic>? ??
        const <String, dynamic>{};

    final kpiCards = [
      EnterpriseStatCard(
        title: 'Movimentos',
        value: '${dash['totalMovimentos'] ?? _items.length}',
        icon: Icons.verified_user_outlined,
        accent: StatCardAccent.info,
      ),
      EnterpriseStatCard(
        title: 'Entradas',
        value: '${dash['entradas'] ?? 0}',
        icon: Icons.login,
        accent: StatCardAccent.positive,
      ),
      EnterpriseStatCard(
        title: 'Saídas',
        value: '${dash['saidas'] ?? 0}',
        icon: Icons.logout,
        accent: StatCardAccent.warning,
      ),
    ];

    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = !constraints.isTabletOrWider;

        return PageRefreshBinder(
          onRefresh: () async {
            await _load();
          },
          child: EnterpriseModuleHub(
            title: 'Auditoria de psicotrópicos',
            subtitle: 'Livro B, receitas, retenção e cruzamento regulatório.',
            tag: 'Auditoria',
            mobileKpisHorizontalScroll: true,
            kpis: isMobile ? null : kpiCards,
            filters: isMobile
                ? null
                : EnterpriseDesktopListToolbar(
                    searchController: _searchController,
                    searchHint: 'Produto, documento...',
                    isLoading: _loading,
                    onSearchSubmitted: _onSearchSubmitted,
                    hasFilters: _search.isNotEmpty,
                    onClearFilters: () {
                      _searchController.clear();
                      _onSearchSubmitted('');
                    },
                    filterWidgets: const [],
                  ),
            child: EnterpriseAdaptiveListBody(
              isMobile: isMobile,
              isLoading: _loading && _items.isEmpty,
              errorText: _error != null && _items.isEmpty ? _error : null,
              desktopToolbar: null,
              desktopContent: _buildDesktopContent(context),
              desktopPagination: !_loading && _items.isNotEmpty
                  ? MovimentacoesPagination(
                      page: _page,
                      pageSize: _pageSize,
                      hasMore: _hasMore,
                      isBusy: _loading,
                      onPrev: _page > 1
                          ? () {
                              _page -= 1;
                              _load();
                            }
                          : null,
                      onNext: _hasMore
                          ? () {
                              _page += 1;
                              _load();
                            }
                          : null,
                      onPageSizeChanged: (size) {
                        _pageSize = size;
                        _page = 1;
                        _load();
                      },
                    )
                  : null,
              mobileList: EnterpriseMobileScrollList(
                kpis: kpiCards,
                stickyHeader: EnterpriseMobileToolbar(
                  searchController: _searchController,
                  searchHint: 'Produto, documento...',
                  enabled: !_loading,
                  isLoading: _loading,
                  hasFilters: _search.isNotEmpty,
                  showFiltersButton: false,
                  onSearchSubmitted: _onSearchSubmitted,
                  onOpenFilters: () {},
                  onClearFilters: _search.isNotEmpty
                      ? () async {
                          _searchController.clear();
                          _onSearchSubmitted('');
                        }
                      : null,
                  onRefresh: () => _load(),
                ),
                itemCount: _accumulatedItems.length,
                itemBuilder: (context, index) =>
                    _AuditPsychoMobileCard(item: _accumulatedItems[index]),
                hasMore: _hasMore,
                isLoading: _loading,
                onLoadMore: () {
                  _page += 1;
                  _load();
                },
                emptyMessage: 'Sem movimentos auditáveis',
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopContent(BuildContext context) {
    if (_loading && _items.isEmpty) return const ModuleLoadingState();
    if (_error != null && _items.isEmpty) {
      return ModuleErrorState(
        title: 'Falha ao carregar auditoria',
        message: _error!,
        onRetry: () => _load(),
        icon: Icons.verified_user_outlined,
      );
    }
    if (_items.isEmpty) {
      return const ModuleEmptyState(
        title: 'Sem movimentos auditáveis',
        subtitle:
            'Não existem registos de psicotrópicos para os filtros actuais.',
      );
    }

    final t = context.pharmaTokens;
    return EnterpriseDataTable(
      columns: [
        for (final label in [
          'Data',
          'Documento',
          'Produto',
          'Movimento',
          'Qtd',
        ])
          DataColumn(
            label: Text(
              label.toUpperCase(),
              style: Theme.of(
                context,
              ).textTheme.erpOverline.copyWith(color: t.textMuted),
            ),
          ),
      ],
      rowCount: _items.length,
      rowBuilder: (context, index) {
        final item = _items[index];
        final createdAt =
            DateTime.tryParse(item['createdAt']?.toString() ?? '') ??
            DateTime.now();
        return DataRow(
          cells: [
            DataCell(
              Text(
                _dateTime.format(createdAt),
                style: Theme.of(
                  context,
                ).textTheme.erpCaption.copyWith(color: t.textMuted),
              ),
            ),
            DataCell(
              Text(
                item['numeroDocumento']?.toString() ?? '—',
                style: Theme.of(
                  context,
                ).textTheme.erpLabel.copyWith(color: t.textPrimary),
              ),
            ),
            DataCell(
              Text(
                item['produto']?['nome']?.toString() ?? '—',
                style: Theme.of(context).textTheme.erpBodySecondary
                    .copyWith(color: t.textSecondary),
              ),
            ),
            DataCell(
              Text(
                item['tipoMovimento']?.toString() ?? '—',
                style: Theme.of(
                  context,
                ).textTheme.erpBody.copyWith(color: t.textPrimary),
              ),
            ),
            DataCell(
              Text(
                '${item['quantidade'] ?? 0}',
                style: Theme.of(
                  context,
                ).textTheme.erpTabLabel.copyWith(color: t.brandGreen),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AuditPsychoMobileCard extends StatelessWidget {
  const _AuditPsychoMobileCard({required this.item});

  final Map<String, dynamic> item;

  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    final createdAt =
        DateTime.tryParse(item['createdAt']?.toString() ?? '') ?? DateTime.now();

    return EnterpriseListCard(
      title: item['produto']?['nome']?.toString() ?? '—',
      subtitle: item['numeroDocumento']?.toString() ?? '—',
      leading: Icons.verified_user_outlined,
      metadata: [
        EnterpriseListCardMeta(
          label: 'Movimento: ${item['tipoMovimento'] ?? '—'}',
        ),
        EnterpriseListCardMeta(
          label: 'Qtd: ${item['quantidade'] ?? 0}',
        ),
        EnterpriseListCardMeta(
          label: 'Data: ${_dateTime.format(createdAt)}',
        ),
      ],
    );
  }
}
