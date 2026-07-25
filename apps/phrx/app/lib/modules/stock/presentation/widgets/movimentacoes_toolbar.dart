import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/responsive/pharma_screen_layout.dart';
import '../../../../shared/widgets/inputs/enterprise_select_field.dart';
import '../../domain/entities/movimentacao.dart';
import '../providers/movimentacao_provider.dart';

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
    final t = context.pharmaTokens;
    final s = context.spacing;
    final screen = context.pharmaScreen;
    final query = state.query;
    final notifier = ref.read(movimentacaoListProvider.notifier);

    final searchField = TextField(
      controller: searchController,
      onChanged: notifier.onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Pesquisar produto, lote, origem, documento ou utilizador...',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: t.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.radiusXl),
          borderSide: BorderSide(color: t.border.withValues(alpha: 0.45)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.radiusXl),
          borderSide: BorderSide(color: t.border.withValues(alpha: 0.45)),
        ),
        isDense: true,
      ),
    );

    final dateChips = <Widget>[
      for (final filter in MovimentacaoQuickFilter.values.where(
        (item) => item != MovimentacaoQuickFilter.none,
      ))
        FilterChip(
          selected: query.quickFilter == filter,
          label: Text(_quickFilterLabel(filter)),
          onSelected: (_) => notifier.setQuickFilter(filter),
        ),
    ];

    final hasCustomDateRange =
        query.dataInicio != null &&
        query.dataFim != null &&
        query.quickFilter == MovimentacaoQuickFilter.none;

    final dateRangeButton = OutlinedButton.icon(
      onPressed: state.isBusy
          ? null
          : () async {
              final now = DateTime.now();
              final initialRange =
                  query.dataInicio != null && query.dataFim != null
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
              if (pickedRange == null) {
                return;
              }
              await notifier.setDateRange(pickedRange);
            },
      icon: const Icon(Icons.date_range_rounded),
      label: Text(
        hasCustomDateRange
            ? _formatDateRange(query.dataInicio!, query.dataFim!)
            : 'Intervalo',
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: hasCustomDateRange
            ? t.brandBlue.withValues(alpha: 0.08)
            : null,
      ),
    );

    final tipoDropdown = EnterpriseSelectField<String>(
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
      onChanged: state.isBusy ? null : notifier.setTipoFilter,
    );

    final origemDropdown = EnterpriseSelectField<String>(
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
      onChanged: state.isBusy ? null : notifier.setOrigemFilter,
    );

    final clearButton = query.hasFilters
        ? TextButton.icon(
            onPressed: state.isBusy ? null : notifier.clearFilters,
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: const Text('Limpar'),
          )
        : null;

    if (screen == PharmaScreenSize.mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          SizedBox(height: s.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                dateRangeButton,
                SizedBox(width: s.sm),
                ...dateChips.expand((chip) => [chip, SizedBox(width: s.sm)]),
              ],
            ),
          ),
          SizedBox(height: s.sm),
          tipoDropdown,
          SizedBox(height: s.sm),
          origemDropdown,
          if (clearButton != null) ...[
            SizedBox(height: s.sm),
            Align(alignment: Alignment.centerLeft, child: clearButton),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: searchField,
              ),
            ),
            SizedBox(width: s.md),
            Expanded(child: tipoDropdown),
            SizedBox(width: s.md),
            Expanded(child: origemDropdown),
            if (clearButton != null) ...[SizedBox(width: s.sm), clearButton],
          ],
        ),
        SizedBox(height: s.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: dateRangeButton,
              ),
            ),
            SizedBox(width: s.md),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: s.sm,
                  runSpacing: s.sm,
                  alignment: WrapAlignment.end,
                  children: dateChips,
                ),
              ),
            ),
          ],
        ),
        if (hasCustomDateRange) ...[
          SizedBox(height: s.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Intervalo activo: ${_formatDateRange(query.dataInicio!, query.dataFim!)}',
              style: Theme.of(context).textTheme.erpCaption.copyWith(color: t.textMuted),
            ),
          ),
        ],
      ],
    );
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
}
