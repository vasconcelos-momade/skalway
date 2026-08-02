import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/widgets/inputs/enterprise_select_field.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../domain/entities/movimentacao.dart';
import '../providers/movimentacao_provider.dart';

/// Toolbar desktop: `[ Pesquisa ] …… [Filtros ▾]` — filtros no painel, não inline.
class MovimentacoesToolbar extends ConsumerWidget {
  const MovimentacoesToolbar({
    super.key,
    required this.searchController,
    required this.state,
  });

  final TextEditingController searchController;
  final MovimentacaoListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = state.query;
    final notifier = ref.read(movimentacaoListProvider.notifier);

    return EnterpriseDesktopListToolbar(
      searchController: searchController,
      searchHint: 'Pesquisar produto, lote, origem, documento ou utilizador...',
      isLoading: state.isBusy,
      onSearchSubmitted: notifier.onSearchChanged,
      hasFilters: query.hasFilters,
      onClearFilters: state.isBusy ? null : notifier.clearFilters,
      onApplyFilters: () {},
      filterWidgets: buildMovimentacoesFilterWidgets(
        context: context,
        state: state,
        notifier: notifier,
      ),
    );
  }
}

/// Toolbar mobile com pesquisa + botão de filtros (bottom sheet).
class MovimentacoesMobileToolbar extends ConsumerWidget {
  const MovimentacoesMobileToolbar({
    super.key,
    required this.searchController,
    required this.state,
  });

  final TextEditingController searchController;
  final MovimentacaoListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = state.query;
    final notifier = ref.read(movimentacaoListProvider.notifier);

    return EnterpriseMobileToolbar(
      searchController: searchController,
      searchHint: 'Produto, lote, origem...',
      enabled: !state.isBusy,
      isLoading: state.isBusy,
      hasFilters: query.hasFilters,
      onSearchSubmitted: notifier.onSearchChanged,
      onOpenFilters: () => _openMobileFilters(context, ref),
      onClearFilters: query.hasFilters
          ? () async => notifier.clearFilters()
          : null,
      onRefresh: notifier.refresh,
    );
  }

  Future<void> _openMobileFilters(BuildContext context, WidgetRef ref) {
    return showEnterpriseFiltersSheet(
      context: context,
      child: _MovimentacoesFiltersBottomSheet(state: state),
    );
  }
}

List<Widget> buildMovimentacoesFilterWidgets({
  required BuildContext context,
  required MovimentacaoListState state,
  required MovimentacaoListController notifier,
}) {
  final t = context.pharmaTokens;
  final query = state.query;
  final busy = state.isBusy;

  final hasCustomDateRange =
      query.dataInicio != null &&
      query.dataFim != null &&
      query.quickFilter == MovimentacaoQuickFilter.none;

  return [
    EnterpriseSelectField<String>(
      key: ValueKey('mov-tipo-${query.tipo}'),
      label: 'Tipo',
      emptyLabel: 'Todos os tipos',
      value: query.tipo,
      options: [
        for (final option in state.filters.tipos)
          EnterpriseSelectOption<String>(
            value: option.value,
            label: option.label,
          ),
      ],
      onChanged: busy ? null : notifier.setTipoFilter,
    ),
    EnterpriseSelectField<String>(
      key: ValueKey('mov-origem-${query.origem}'),
      label: 'Origem',
      emptyLabel: 'Todas as origens',
      value: query.origem,
      options: [
        for (final option in state.filters.origens)
          EnterpriseSelectOption<String>(
            value: option.value,
            label: option.label,
          ),
      ],
      onChanged: busy ? null : notifier.setOrigemFilter,
    ),
    EnterpriseSelectField<MovimentacaoQuickFilter>(
      key: ValueKey('mov-quick-${query.quickFilter}'),
      label: 'Período rápido',
      emptyLabel: 'Nenhum',
      value: query.quickFilter == MovimentacaoQuickFilter.none
          ? null
          : query.quickFilter,
      options: [
        for (final filter in MovimentacaoQuickFilter.values.where(
          (item) => item != MovimentacaoQuickFilter.none,
        ))
          EnterpriseSelectOption<MovimentacaoQuickFilter>(
            value: filter,
            label: _quickFilterLabel(filter),
          ),
      ],
      onChanged: busy
          ? null
          : (value) =>
                notifier.setQuickFilter(value ?? MovimentacaoQuickFilter.none),
    ),
    OutlinedButton.icon(
      onPressed: busy
          ? null
          : () => _pickDateRange(context, query, notifier),
      icon: Icon(Icons.date_range_rounded, size: t.iconSm),
      label: Text(
        hasCustomDateRange
            ? _formatDateRange(query.dataInicio!, query.dataFim!)
            : 'Intervalo personalizado',
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(0, t.controlHeight),
        backgroundColor: hasCustomDateRange
            ? t.brandBlue.withValues(alpha: 0.08)
            : null,
      ),
    ),
    if (hasCustomDateRange)
      Text(
        'Intervalo activo: ${_formatDateRange(query.dataInicio!, query.dataFim!)}',
        style: Theme.of(context).textTheme.erpCaption.copyWith(
              color: t.textMuted,
            ),
      ),
  ];
}

Future<void> _pickDateRange(
  BuildContext context,
  MovimentacaoQuery query,
  MovimentacaoListController notifier,
) async {
  final now = DateTime.now();
  final initialRange = query.dataInicio != null && query.dataFim != null
      ? DateTimeRange(start: query.dataInicio!, end: query.dataFim!)
      : DateTimeRange(
          start: DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(const Duration(days: 6)),
          end: DateTime(now.year, now.month, now.day),
        );
  final pickedRange = await showDateRangePicker(
    context: context,
    initialDateRange: initialRange,
    firstDate: DateTime(now.year - 5),
    lastDate: DateTime(now.year + 5),
    helpText: 'Seleccionar intervalo',
    cancelText: 'Cancelar',
    confirmText: 'Aplicar',
    saveText: 'Aplicar',
    fieldStartHintText: 'Data inicial',
    fieldEndHintText: 'Data final',
  );
  if (pickedRange == null) return;
  await notifier.setDateRange(pickedRange);
}

String _quickFilterLabel(MovimentacaoQuickFilter filter) {
  return switch (filter) {
    MovimentacaoQuickFilter.today => 'Hoje',
    MovimentacaoQuickFilter.week => 'Semana',
    MovimentacaoQuickFilter.month => 'Mês',
    MovimentacaoQuickFilter.none => 'Todas',
  };
}

String _formatDateRange(DateTime start, DateTime end) {
  return '${_formatDate(start)} - ${_formatDate(end)}';
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year;
  return '$day/$month/$year';
}

class _MovimentacoesFiltersBottomSheet extends ConsumerStatefulWidget {
  const _MovimentacoesFiltersBottomSheet({required this.state});

  final MovimentacaoListState state;

  @override
  ConsumerState<_MovimentacoesFiltersBottomSheet> createState() =>
      _MovimentacoesFiltersBottomSheetState();
}

class _MovimentacoesFiltersBottomSheetState
    extends ConsumerState<_MovimentacoesFiltersBottomSheet> {
  late String? _tipo = widget.state.query.tipo;
  late String? _origem = widget.state.query.origem;
  late MovimentacaoQuickFilter _quickFilter = widget.state.query.quickFilter;
  late DateTime? _dataInicio = widget.state.query.dataInicio;
  late DateTime? _dataFim = widget.state.query.dataFim;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final t = context.pharmaTokens;
    final scheme = Theme.of(context).colorScheme;
    final notifier = ref.read(movimentacaoListProvider.notifier);
    final hasCustomDateRange =
        _dataInicio != null &&
        _dataFim != null &&
        _quickFilter == MovimentacaoQuickFilter.none;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(context.radius.lg),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          s.md,
          s.md,
          s.md,
          s.md + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filtros',
                style: Theme.of(context).textTheme.erpSectionTitle,
              ),
              SizedBox(height: s.md),
              EnterpriseSelectField<String>(
                key: ValueKey('sheet-mov-tipo-$_tipo'),
                label: 'Tipo',
                emptyLabel: 'Todos os tipos',
                value: _tipo,
                options: [
                  for (final option in widget.state.filters.tipos)
                    EnterpriseSelectOption<String>(
                      value: option.value,
                      label: option.label,
                    ),
                ],
                onChanged: (value) => setState(() => _tipo = value),
              ),
              SizedBox(height: s.md),
              EnterpriseSelectField<String>(
                key: ValueKey('sheet-mov-origem-$_origem'),
                label: 'Origem',
                emptyLabel: 'Todas as origens',
                value: _origem,
                options: [
                  for (final option in widget.state.filters.origens)
                    EnterpriseSelectOption<String>(
                      value: option.value,
                      label: option.label,
                    ),
                ],
                onChanged: (value) => setState(() => _origem = value),
              ),
              SizedBox(height: s.md),
              EnterpriseSelectField<MovimentacaoQuickFilter>(
                key: ValueKey('sheet-mov-quick-$_quickFilter'),
                label: 'Período rápido',
                emptyLabel: 'Nenhum',
                value: _quickFilter == MovimentacaoQuickFilter.none
                    ? null
                    : _quickFilter,
                options: [
                  for (final filter in MovimentacaoQuickFilter.values.where(
                    (item) => item != MovimentacaoQuickFilter.none,
                  ))
                    EnterpriseSelectOption<MovimentacaoQuickFilter>(
                      value: filter,
                      label: _quickFilterLabel(filter),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _quickFilter = value ?? MovimentacaoQuickFilter.none;
                  if (_quickFilter != MovimentacaoQuickFilter.none) {
                    _dataInicio = null;
                    _dataFim = null;
                  }
                }),
              ),
              SizedBox(height: s.md),
              OutlinedButton.icon(
                onPressed: () async {
                  final now = DateTime.now();
                  final initialRange =
                      _dataInicio != null && _dataFim != null
                      ? DateTimeRange(start: _dataInicio!, end: _dataFim!)
                      : DateTimeRange(
                          start: DateTime(
                            now.year,
                            now.month,
                            now.day,
                          ).subtract(const Duration(days: 6)),
                          end: DateTime(now.year, now.month, now.day),
                        );
                  final picked = await showDateRangePicker(
                    context: context,
                    initialDateRange: initialRange,
                    firstDate: DateTime(now.year - 5),
                    lastDate: DateTime(now.year + 5),
                    helpText: 'Seleccionar intervalo',
                    cancelText: 'Cancelar',
                    confirmText: 'Aplicar',
                  );
                  if (picked == null) return;
                  setState(() {
                    _dataInicio = picked.start;
                    _dataFim = picked.end;
                    _quickFilter = MovimentacaoQuickFilter.none;
                  });
                },
                icon: Icon(Icons.date_range_rounded, size: t.iconSm),
                label: Text(
                  hasCustomDateRange
                      ? _formatDateRange(_dataInicio!, _dataFim!)
                      : 'Intervalo personalizado',
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, t.controlHeight),
                ),
              ),
              SizedBox(height: s.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await notifier.clearFilters();
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: const Text('Limpar'),
                    ),
                  ),
                  SizedBox(width: s.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        if (_quickFilter != MovimentacaoQuickFilter.none) {
                          await notifier.setQuickFilter(_quickFilter);
                        } else if (_dataInicio != null && _dataFim != null) {
                          await notifier.setDateRange(
                            DateTimeRange(
                              start: _dataInicio!,
                              end: _dataFim!,
                            ),
                          );
                        } else {
                          await notifier.setDateRange(null);
                        }
                        await notifier.setTipoFilter(_tipo);
                        await notifier.setOrigemFilter(_origem);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: const Text('Aplicar'),
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
}
