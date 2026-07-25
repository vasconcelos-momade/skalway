import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/extensions/async_value_extensions.dart';
import '../../../../../core/constants/report_paths.dart';
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
import '../../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../../../lots/presentation/widgets/open_lote_details.dart';
import '../../../presentation/widgets/pharmacy_report_exports.dart';
import '../providers/expiry_provider.dart';

class ExpiryPage extends ConsumerStatefulWidget {
  const ExpiryPage({super.key});

  @override
  ConsumerState<ExpiryPage> createState() => _ExpiryPageState();
}

class _ExpiryPageState extends ConsumerState<ExpiryPage> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _accumulatedItems = [];

  static const _bucketOptions = <(String, String)>[
    ('expirado', 'Expirados'),
    ('30', '30d'),
    ('60', '60d'),
    ('todos', 'Todos'),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Color _rowColor(BuildContext context, String? estado) {
    final t = context.pharmaTokens;
    switch (estado) {
      case 'EXPIRADO':
        return t.posDanger;
      case 'ATE_30_DIAS':
        return Colors.orange;
      case 'ATE_60_DIAS':
        return Colors.amber.shade700;
      default:
        return t.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(expiryViewProvider);
    final controller = ref.read(expiryViewProvider.notifier);
    final state = asyncState.valueOrNull;
    final dash = state?.dashboard;
    final reportQuery = <String, dynamic>{
      if ((state?.query ?? '').isNotEmpty) 'q': state!.query,
      'bucket': state?.bucket ?? 'todos',
    };
    final hasFilters = (state?.bucket ?? 'todos') != 'todos';
    final kpis = dash == null
        ? null
        : [
            EnterpriseStatCard(
              title: 'Expirados',
              value: '${dash['lotesExpirados'] ?? 0}',
              icon: Icons.warning_amber_rounded,
            ),
            EnterpriseStatCard(
              title: '30 dias',
              value: '${dash['expiramEm30Dias'] ?? 0}',
              icon: Icons.schedule,
            ),
            EnterpriseStatCard(
              title: '60 dias',
              value: '${dash['expiramEm60Dias'] ?? 0}',
              icon: Icons.calendar_month_outlined,
            ),
            EnterpriseStatCard(
              title: 'Valor em risco',
              value: '${dash['valorFinanceiroEmRisco'] ?? 0} MZN',
              icon: Icons.payments_outlined,
            ),
          ];

    ref.listen(expiryViewProvider, (prev, next) {
      final previous = prev?.valueOrNull;
      final upcoming = next.valueOrNull;
      if (upcoming == null) return;

      if (previous?.page != upcoming.page ||
          previous?.query != upcoming.query ||
          previous?.bucket != upcoming.bucket ||
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

    if (state != null && _search.text != state.query) {
      _search.value = TextEditingValue(
        text: state.query,
        selection: TextSelection.collapsed(offset: state.query.length),
      );
    }

    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = !constraints.isTabletOrWider;

        return EnterpriseModuleHub(
          mobileKpisHorizontalScroll: true,
          kpis: isMobile ? null : kpis,
          actions: null,
          filters: null,
          child: EnterpriseAdaptiveListBody(
            isMobile: isMobile,
            isLoading: asyncState.isLoading,
            errorText: asyncState.hasError ? asyncState.error.toString() : null,
            desktopToolbar: EnterpriseDesktopListToolbar(
              searchController: _search,
              searchHint: 'Pesquisar produto ou lote...',
              isLoading: asyncState.isLoading,
              onSearchSubmitted: controller.setSearch,
              hasFilters: hasFilters,
              onClearFilters: () => controller.setBucket('todos'),
              filterWidgets: [
                for (final option in _bucketOptions)
                  FilterChip(
                    label: Text(option.$2),
                    selected: (state?.bucket ?? 'todos') == option.$1,
                    onSelected: (_) => controller.setBucket(option.$1),
                  ),
              ],
              trailingActions: [
                ...pharmacyReportActions(
                  ref: ref,
                  enabled: !asyncState.isLoading,
                  path: ReportPaths.expiry,
                  queryParameters: reportQuery,
                ),
                IconButton(
                  onPressed: () => controller.refresh(force: true),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            desktopContent: _buildTableContent(
              context: context,
              asyncState: asyncState,
              state: state,
            ),
            desktopPagination: state?.totalCount != null
                ? EnterprisePagination(
                    page: state?.page ?? 1,
                    pageSize: state?.pageSize ?? 20,
                    totalCount: state!.totalCount!,
                    itemLabel: 'lotes',
                    isBusy: asyncState.isLoading,
                    onPageChanged: controller.goToPage,
                    onPageSizeChanged: controller.setPageSize,
                  )
                : null,
            mobileList: EnterpriseMobileScrollList(
              kpis: kpis,
              stickyHeader: EnterpriseMobileToolbar(
                searchController: _search,
                searchHint: 'Produto ou nº lote...',
                enabled: !asyncState.isLoading,
                isLoading: asyncState.isLoading,
                hasFilters: hasFilters,
                onSearchSubmitted: controller.setSearch,
                onOpenFilters: () =>
                    _openMobileFilters(context, controller, state),
                onClearFilters: () async => controller.setBucket('todos'),
                onRefresh: () => controller.refresh(force: true),
                reportAction: pharmacyReportActions(
                  ref: ref,
                  enabled: !asyncState.isLoading,
                  path: ReportPaths.expiry,
                  queryParameters: reportQuery,
                  expandChild: true,
                ).single,
              ),
              itemCount: _accumulatedItems.length,
              itemBuilder: (context, index) => _ExpiryMobileCard(
                item: _accumulatedItems[index],
                validadeColor: _rowColor(
                  context,
                  _accumulatedItems[index]['estado'] as String?,
                ),
                onTap: () => _openLotDrawer(
                  _accumulatedItems[index]['id']?.toString() ?? '',
                ),
              ),
              hasMore: state?.hasMore ?? false,
              isLoading: asyncState.isLoading,
              onLoadMore: () => controller.goToPage((state?.page ?? 1) + 1),
              emptyMessage: state?.bucket == 'todos'
                  ? 'Nenhum lote com stock activo.'
                  : 'Nenhum lote neste filtro de validade.',
              totalCount: state?.totalCount,
              totalCountLabel: state?.totalCount != null
                  ? 'Total: ${state!.totalCount} lote(s)'
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableContent({
    required BuildContext context,
    required AsyncValue<ExpiryViewState> asyncState,
    required ExpiryViewState? state,
  }) {
    if (asyncState.isLoading && state == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = state?.items ?? const <Map<String, dynamic>>[];
    if (items.isEmpty) {
      return Center(
        child: Text(
          state?.bucket == 'todos'
              ? 'Nenhum lote com stock activo.'
              : 'Nenhum lote neste filtro de validade.',
          style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
            color: context.pharmaTokens.textMuted,
          ),
        ),
      );
    }

    return EnterpriseDataTable(
      adaptive: false,
      columns: const [
        DataColumn(label: Text('PRODUTO')),
        DataColumn(label: Text('LOTE')),
        DataColumn(label: Text('VALIDADE')),
        DataColumn(label: Text('DIAS')),
        DataColumn(label: Text('QTD')),
        DataColumn(label: Text('VALOR')),
        DataColumn(label: Text('ESTADO')),
      ],
      rowCount: items.length,
      rowBuilder: (context, index) {
        final item = items[index];
        final color = _rowColor(context, item['estado'] as String?);
        return DataRow(
          onSelectChanged: (_) => _openLotDrawer(item['id']?.toString() ?? ''),
          cells: [
            DataCell(Text(item['produtoNomeComercial']?.toString() ?? item['produtoNome']?.toString() ?? '—')),
            DataCell(Text(item['numeroLote']?.toString() ?? '—')),
            DataCell(Text(_formatDate(item['dataValidade']))),
            DataCell(
              Text(
                '${item['diasRestantes'] ?? '—'}',
                style: Theme.of(
                  context,
                ).textTheme.erpLabel.copyWith(color: color),
              ),
            ),
            DataCell(Text(LoteStockUtils.formatDisponivel(item))),
            DataCell(Text(item['valorEmStock']?.toString() ?? '0')),
            DataCell(Text(item['estado']?.toString() ?? '—')),
          ],
        );
      },
    );
  }

  void _openMobileFilters(
    BuildContext context,
    ExpiryViewController controller,
    ExpiryViewState? state,
  ) {
    showEnterpriseFiltersSheet(
      context: context,
      child: _ExpiryFiltersSheet(
        initialBucket: state?.bucket ?? 'todos',
        onApply: controller.setBucket,
      ),
    );
  }

  String _formatDate(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return '—';
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }

  Future<void> _openLotDrawer(String loteId) =>
      openLoteDetails(context, loteId);
}

class _ExpiryFiltersSheet extends StatelessWidget {
  const _ExpiryFiltersSheet({
    required this.initialBucket,
    required this.onApply,
  });

  static const _bucketOptions = <(String, String)>[
    ('expirado', 'Expirados'),
    ('30', '30d'),
    ('60', '60d'),
    ('todos', 'Todos'),
  ];

  final String initialBucket;
  final ValueChanged<String> onApply;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    var bucket = initialBucket;

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
                'Filtros de validade',
                style: Theme.of(context).textTheme.erpSectionTitle,
              ),
              SizedBox(height: s.md),
              Wrap(
                spacing: s.sm,
                runSpacing: s.sm,
                children: [
                  for (final option in _bucketOptions)
                    FilterChip(
                      label: Text(option.$2),
                      selected: bucket == option.$1,
                      onSelected: (_) => setState(() => bucket = option.$1),
                    ),
                ],
              ),
              SizedBox(height: s.lg),
              FilledButton(
                onPressed: () {
                  onApply(bucket);
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

class _ExpiryMobileCard extends StatelessWidget {
  const _ExpiryMobileCard({
    required this.item,
    required this.validadeColor,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final Color validadeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return EnterpriseListCard(
      leading: Icons.event_outlined,
      title: item['produtoNomeComercial']?.toString() ?? item['produtoNome']?.toString() ?? '—',
      subtitle: 'Lote: ${item['numeroLote']?.toString() ?? '—'}',
      chip: EnterpriseStatusChip(
        label: item['estado']?.toString() ?? '—',
        color: validadeColor,
      ),
      metadata: [
        EnterpriseListCardMeta(
          label:
              'Validade: ${_formatDate(item['dataValidade'])} (${item['diasRestantes'] ?? '—'} dias)',
          color: validadeColor,
        ),
        EnterpriseListCardMeta(
          label:
              'Qtd: ${LoteStockUtils.formatDisponivel(item)} · Valor: ${item['valorEmStock']?.toString() ?? '0'}',
        ),
      ],
      onTap: onTap,
    );
  }

  static String _formatDate(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return '—';
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }
}
