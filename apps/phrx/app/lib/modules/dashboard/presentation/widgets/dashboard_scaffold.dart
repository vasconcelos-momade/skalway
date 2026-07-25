import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../core/theme/spacing.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../domain/dashboard_query.dart';
import '../../domain/models/dashboard_table_definition.dart';
import 'dashboard_header_actions.dart';
import 'dashboard_period_filters.dart';
import 'dashboard_widgets.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';

/// Configuração partilhada de filtros por tipo de painel.
class DashboardFilterPreset {
  const DashboardFilterPreset({
    this.showCategoryFilter = false,
    this.showProductFilter = false,
    this.statusOptions = const [],
    this.paymentMethodOptions = const [],
    this.movementTypeOptions = const [],
    this.actionsInFilters = false,
  });

  final bool showCategoryFilter;
  final bool showProductFilter;
  final List<DashboardFilterOption> statusOptions;
  final List<DashboardFilterOption> paymentMethodOptions;
  final List<DashboardFilterOption> movementTypeOptions;
  final bool actionsInFilters;
}

typedef DashboardProviderFamily =
    FutureProvider<Map<String, dynamic>> Function(DashboardQuery query);

/// Shell reutilizável para páginas de dashboard (query, filtros, async body).
class DashboardScaffold extends ConsumerStatefulWidget {
  const DashboardScaffold({
    super.key,
    this.title,
    this.subtitle,
    this.tag,
    required this.provider,
    required this.reportPath,
    required this.exportSuccessMessage,
    required this.contentBuilder,
    this.filterPreset = const DashboardFilterPreset(),
    this.filterPresetBuilder,
    this.loadingKpiCount = 5,
    this.extraFilters,
  });

  final String? title;
  final String? subtitle;
  final String? tag;
  final DashboardProviderFamily provider;
  final String reportPath;
  final String exportSuccessMessage;
  final Widget Function(
    BuildContext context,
    Map<String, dynamic> data,
    DashboardQuery query,
  ) contentBuilder;
  final DashboardFilterPreset filterPreset;
  final DashboardFilterPreset Function(Map<String, dynamic>? previewData)?
      filterPresetBuilder;
  final int loadingKpiCount;
  final List<Widget>? extraFilters;

  @override
  ConsumerState<DashboardScaffold> createState() => _DashboardScaffoldState();
}

class _DashboardScaffoldState extends ConsumerState<DashboardScaffold> {
  var _query = const DashboardQuery();

  void _invalidate() => ref.invalidate(widget.provider(_query));

  DashboardHeaderActions _headerActions({required bool exportEnabled}) {
    return DashboardHeaderActions(
      onRefresh: _invalidate,
      reportPath: widget.reportPath,
      query: _query,
      exportEnabled: exportEnabled,
      exportSuccessMessage: widget.exportSuccessMessage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(widget.provider(_query));
    final exportEnabled = async.valueOrNull != null;
    final headerActions = _headerActions(exportEnabled: exportEnabled);
    final filters = widget.filterPresetBuilder?.call(async.valueOrNull) ??
        widget.filterPreset;

    return EnterpriseModuleHub(
      title: widget.title,
      subtitle: widget.subtitle,
      tag: widget.tag,
      scrollable: true,
      actions: filters.actionsInFilters ? null : [headerActions],
      filters: DashboardPeriodFilters(
        query: _query,
        onChanged: (query) => setState(() => _query = query),
        showCategoryFilter: filters.showCategoryFilter,
        showProductFilter: filters.showProductFilter,
        statusOptions: filters.statusOptions,
        paymentMethodOptions: filters.paymentMethodOptions,
        movementTypeOptions: filters.movementTypeOptions,
        extraFilters: widget.extraFilters,
        actions: filters.actionsInFilters ? [headerActions] : null,
      ),
      child: dashboardAsyncBody(
        async: async,
        onRetry: _invalidate,
        loadingKpiCount: widget.loadingKpiCount,
        builder: (Map<String, dynamic> data) =>
            widget.contentBuilder(context, data, _query),
      ),
    );
  }
}

/// Espaçamento vertical padrão entre secções do dashboard.
class DashboardSectionGap extends StatelessWidget {
  const DashboardSectionGap({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(height: AppSpacing.lg);
}

typedef DashboardTableFetcher = Future<Map<String, dynamic>> Function({
  required String table,
  required DashboardQuery query,
  required int page,
  required int pageSize,
});

/// Renderiza uma lista de tabelas paginadas com fetcher partilhado.
class DashboardTablesSection extends StatelessWidget {
  const DashboardTablesSection({
    super.key,
    required this.definitions,
    required this.fetcher,
    required this.query,
  });

  final List<DashboardTableDefinition> definitions;
  final DashboardTableFetcher fetcher;
  final DashboardQuery query;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < definitions.length; i++) ...[
          if (i > 0) const DashboardSectionGap(),
          _DashboardTableTile(
            definition: definitions[i],
            fetcher: fetcher,
            query: query,
          ),
        ],
      ],
    );
  }
}

class _DashboardTableTile extends StatelessWidget {
  const _DashboardTableTile({
    required this.definition,
    required this.fetcher,
    required this.query,
  });

  final DashboardTableDefinition definition;
  final DashboardTableFetcher fetcher;
  final DashboardQuery query;

  @override
  Widget build(BuildContext context) {
    return DashboardPaginatedTable(
      title: definition.title,
      headers: definition.headers,
      reloadKey: '${query.reloadKey}-${definition.reloadKeySuffix}',
      loadPage: (page, pageSize, sortBy, sortDir) async {
        final result = await fetcher(
          table: definition.tableKey,
          query: query.copyWith(
            sortBy: sortBy,
            sortDir: sortDir,
            clearSortBy: sortBy == null,
          ),
          page: page,
          pageSize: pageSize,
        );
        return DashboardPagedTableResult.fromMap(result);
      },
      rowBuilder: definition.rowBuilder,
    );
  }
}

DashboardTableFetcher financeTableFetcher(DashboardRemoteDataSource source) {
  return ({
    required table,
    required query,
    required page,
    required pageSize,
  }) {
    return source.financeDashboardTable(
      table: table,
      query: query,
      page: page,
      pageSize: pageSize,
    );
  };
}

DashboardTableFetcher pharmacyTableFetcher(DashboardRemoteDataSource source) {
  return ({
    required table,
    required query,
    required page,
    required pageSize,
  }) {
    return source.pharmacyDashboardTable(
      table: table,
      query: query,
      page: page,
      pageSize: pageSize,
    );
  };
}

DashboardTableFetcher stockTableFetcher(DashboardRemoteDataSource source) {
  return ({
    required table,
    required query,
    required page,
    required pageSize,
  }) {
    return source.stockDashboardTable(
      table: table,
      query: query,
      page: page,
      pageSize: pageSize,
    );
  };
}
