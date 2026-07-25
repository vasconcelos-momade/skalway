import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../shared/responsive/pharma_screen_layout.dart';
import '../providers/dashboard_providers.dart';
import '../../domain/dashboard_query.dart';
import 'dashboard_widgets.dart';

typedef DashboardQueryChanged = void Function(DashboardQuery query);

class DashboardPeriodFilters extends ConsumerStatefulWidget {
  const DashboardPeriodFilters({
    super.key,
    required this.query,
    required this.onChanged,
    this.extraFilters,
    this.showCategoryFilter = false,
    this.showProductFilter = false,
    this.statusOptions = const [],
    this.paymentMethodOptions = const [],
    this.movementTypeOptions = const [],
    this.actions,
  });

  final DashboardQuery query;
  final DashboardQueryChanged onChanged;
  final List<Widget>? extraFilters;
  final bool showCategoryFilter;
  final bool showProductFilter;
  final List<DashboardFilterOption> statusOptions;
  final List<DashboardFilterOption> paymentMethodOptions;
  final List<DashboardFilterOption> movementTypeOptions;
  final List<Widget>? actions;

  @override
  ConsumerState<DashboardPeriodFilters> createState() => _DashboardPeriodFiltersState();
}

class _DashboardPeriodFiltersState extends ConsumerState<DashboardPeriodFilters> {
  DashboardQuery get query => widget.query;
  DashboardQueryChanged get onChanged => widget.onChanged;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = widget.showCategoryFilter
        ? ref.watch(dashboardFilterCategoriesProvider)
        : const AsyncValue.data([]);
    final productsAsync = widget.showProductFilter
        ? ref.watch(dashboardFilterProductsProvider)
        : const AsyncValue.data([]);

    final presets = <(DashboardPeriodPreset, String)>[
      (DashboardPeriodPreset.today, 'Hoje'),
      (DashboardPeriodPreset.yesterday, 'Ontem'),
      (DashboardPeriodPreset.last7days, 'Últimos 7 dias'),
      (DashboardPeriodPreset.last30days, 'Últimos 30 dias'),
      (DashboardPeriodPreset.thisMonth, 'Este mês'),
      (DashboardPeriodPreset.lastMonth, 'Mês anterior'),
      (DashboardPeriodPreset.thisYear, 'Este ano'),
      (DashboardPeriodPreset.custom, 'Personalizado'),
    ];

    final hasCustomRange =
        widget.query.period == DashboardPeriodPreset.custom &&
        widget.query.from != null &&
        widget.query.to != null;

    final periodOptions = presets
        .map((p) => DashboardFilterOption(
              value: p.$1.name,
              label: p.$1 == DashboardPeriodPreset.custom && hasCustomRange
                  ? _formatRange(widget.query.from!, widget.query.to!)
                  : p.$2,
            ))
        .toList();

    final categoryOptions = categoriesAsync.maybeWhen(
      data: (items) => items
          .map((item) => DashboardFilterOption(value: item.id, label: item.nome))
          .toList(growable: false),
      orElse: () => const <DashboardFilterOption>[],
    );

    final productOptions = productsAsync.maybeWhen(
      data: (items) => items
          .map((item) => DashboardFilterOption(value: item.id, label: item.nomeComercial))
          .toList(growable: false),
      orElse: () => const <DashboardFilterOption>[],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = context.spacing.sm;
        final availableWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
        final columns = PharmaScreenLayout.adaptiveCrossAxisCount(
          availableWidth,
          280,
          maxColumns: availableWidth >= 1440 ? 5 : 4,
        );
        final fieldWidth =
            ((availableWidth - (columns - 1) * spacing) / columns)
                .clamp(220.0, 360.0);

        Widget filterField(Widget child) => SizedBox(
              width: fieldWidth,
              child: child,
            );

        final filterChildren = <Widget>[
          filterField(
            DashboardFilterSelect(
              label: 'Período',
              options: periodOptions,
              value: query.period.name,
              onChanged: (value) {
                if (value == null) return;
                final preset = DashboardPeriodPreset.values.firstWhere(
                  (p) => p.name == value,
                  orElse: () => DashboardPeriodPreset.today,
                );

                if (preset == DashboardPeriodPreset.custom) {
                  _pickCustomRange(context);
                } else {
                  onChanged(
                    query.copyWith(
                      period: preset,
                      clearFrom: true,
                      clearTo: true,
                      days: preset == DashboardPeriodPreset.last7days
                          ? 7
                          : preset == DashboardPeriodPreset.last30days
                              ? 30
                              : query.days,
                    ),
                  );
                }
              },
            ),
          ),
          if (widget.showCategoryFilter)
            filterField(
              DashboardFilterSelect(
                label: 'Categoria',
                emptyLabel: 'Todas',
                options: categoryOptions,
                value: query.categoriaId,
                onChanged: (value) => onChanged(
                  query.copyWith(
                    categoriaId: value,
                    clearCategoriaId: value == null,
                  ),
                ),
              ),
            ),
          if (widget.showProductFilter)
            filterField(
              DashboardFilterSelect(
                label: 'Produto',
                options: productOptions,
                value: query.produtoId,
                onChanged: (value) => onChanged(
                  query.copyWith(
                    produtoId: value,
                    clearProdutoId: value == null,
                  ),
                ),
              ),
            ),
          if (widget.statusOptions.isNotEmpty)
            filterField(
              DashboardFilterSelect(
                label: 'Estado',
                options: widget.statusOptions,
                value: query.estado,
                onChanged: (value) => onChanged(
                  query.copyWith(
                    estado: value,
                    clearEstado: value == null,
                  ),
                ),
              ),
            ),
          if (widget.paymentMethodOptions.isNotEmpty)
            filterField(
              DashboardFilterSelect(
                label: 'Pagamento',
                options: widget.paymentMethodOptions,
                value: query.metodoPagamento,
                onChanged: (value) => onChanged(
                  query.copyWith(
                    metodoPagamento: value,
                    clearMetodoPagamento: value == null,
                  ),
                ),
              ),
            ),
          if (widget.movementTypeOptions.isNotEmpty)
            filterField(
              DashboardFilterSelect(
                label: 'Movimentação',
                options: widget.movementTypeOptions,
                value: query.tipoMovimentacao,
                onChanged: (value) => onChanged(
                  query.copyWith(
                    tipoMovimentacao: value,
                    clearTipoMovimentacao: value == null,
                  ),
                ),
              ),
            ),
          if (widget.extraFilters != null) ...widget.extraFilters!,
        ];

        return Align(
          alignment: Alignment.centerRight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // Começa do final (direita)
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (var i = 0; i < filterChildren.length; i++) ...[
                  if (i > 0) SizedBox(width: spacing),
                  filterChildren[i],
                ],
                if (query.hasActiveFilters) ...[
                  SizedBox(width: spacing),
                  TextButton.icon(
                    onPressed: () => onChanged(const DashboardQuery()),
                    icon: const Icon(Icons.filter_alt_off_outlined),
                    label: const Text('Limpar'),
                  ),
                ],
                if (widget.actions != null && widget.actions!.isNotEmpty) ...[
                  for (final action in widget.actions!) ...[
                    SizedBox(width: spacing),
                    action,
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final initial = query.from != null && query.to != null
        ? DateTimeRange(start: query.from!, end: query.to!)
        : DateTimeRange(
            start: DateTime(now.year, now.month, now.day)
                .subtract(const Duration(days: 29)),
            end: DateTime(now.year, now.month, now.day),
          );

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      helpText: 'Seleccionar intervalo',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      saveText: 'Aplicar',
      fieldStartHintText: 'Data inicial',
      fieldEndHintText: 'Data final',
    );

    if (picked == null) return;
    onChanged(
      query.copyWith(
        period: DashboardPeriodPreset.custom,
        from: picked.start,
        to: picked.end,
      ),
    );
  }

  String _formatRange(DateTime from, DateTime to) {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    return '${fmt(from)} – ${fmt(to)}';
  }
}
