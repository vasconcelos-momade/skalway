import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../shared/responsive/pharma_screen_layout.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../domain/entities/movimentacao.dart';
import '../providers/movimentacao_provider.dart';
import 'movimentacoes_mobile_card.dart';
import 'movimentacoes_overview_cards.dart';
import 'movimentacoes_pagination.dart';
import 'movimentacoes_state_widgets.dart';
import 'movimentacoes_table.dart';
import 'movimentacoes_toolbar.dart';

class MovimentacoesBody extends ConsumerWidget {
  const MovimentacoesBody({
    super.key,
    required this.searchController,
    required this.listState,
  });

  final TextEditingController searchController;
  final MovimentacaoListState listState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (PharmaScreenLayout.isMobile(context)) {
      return _MovimentacoesMobileBody(
        searchController: searchController,
        listState: listState,
      );
    }

    final s = context.spacing;
    final query = listState.query;
    final notifier = ref.read(movimentacaoListProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MovimentacoesToolbar(
          searchController: searchController,
          state: listState,
        ),
        SizedBox(height: s.md),
        MovimentacoesOverviewCards(
          overview: listState.overview,
          hasFilters: query.hasFilters,
        ),
        if (listState.errorMessage != null) ...[
          SizedBox(height: s.md),
          MovimentacoesInfoBanner(message: listState.errorMessage!),
        ],
        SizedBox(height: s.md),
        Expanded(child: _MovimentacoesResultsPane(listState: listState)),
        SizedBox(height: s.md),
        MovimentacoesPagination(
          page: query.page,
          pageSize: query.pageSize,
          totalCount: listState.overview.totalMovimentos,
          hasMore: listState.hasMore,
          isBusy: listState.isBusy,
          onPageChanged: notifier.goToPage,
          onPageSizeChanged: notifier.setPageSize,
        ),
      ],
    );
  }
}

class _MovimentacoesMobileBody extends ConsumerStatefulWidget {
  const _MovimentacoesMobileBody({
    required this.searchController,
    required this.listState,
  });

  final TextEditingController searchController;
  final MovimentacaoListState listState;

  @override
  ConsumerState<_MovimentacoesMobileBody> createState() =>
      _MovimentacoesMobileBodyState();
}

class _MovimentacoesMobileBodyState
    extends ConsumerState<_MovimentacoesMobileBody> {
  List<Movimentacao> _accumulatedItems = [];

  @override
  void initState() {
    super.initState();
    _accumulatedItems = List.of(widget.listState.items);
  }

  @override
  void didUpdateWidget(covariant _MovimentacoesMobileBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    final prev = oldWidget.listState;
    final next = widget.listState;
    if (prev.query.page != next.query.page ||
        prev.query.search != next.query.search ||
        prev.query.tipo != next.query.tipo ||
        prev.query.origem != next.query.origem ||
        prev.query.quickFilter != next.query.quickFilter ||
        prev.query.dataInicio != next.query.dataInicio ||
        prev.query.dataFim != next.query.dataFim ||
        prev.query.pageSize != next.query.pageSize) {
      if (next.query.page == 1) {
        _accumulatedItems = List.of(next.items);
      } else {
        _accumulatedItems = [
          ..._accumulatedItems,
          ...next.items.where(
            (e) => !_accumulatedItems.any((a) => a.id == e.id),
          ),
        ];
      }
    } else if (prev.items != next.items && next.query.page == 1) {
      _accumulatedItems = List.of(next.items);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listState = widget.listState;
    final notifier = ref.read(movimentacaoListProvider.notifier);
    final kpiCards = MovimentacoesOverviewCards.buildCards(
      overview: listState.overview,
      hasFilters: listState.query.hasFilters,
    );

    return EnterpriseMobileScrollList(
      kpis: kpiCards,
      errorText: listState.errorMessage,
      stickyHeader: MovimentacoesToolbar(
        searchController: widget.searchController,
        state: listState,
      ),
      itemCount: _accumulatedItems.length,
      itemBuilder: (context, index) =>
          MovimentacoesMobileCard(item: _accumulatedItems[index]),
      hasMore: listState.hasMore,
      isLoading: listState.isBusy,
      onLoadMore: () => notifier.goToPage(listState.query.page + 1),
      emptyMessage: 'Nenhuma movimentação registada',
      totalCount: listState.overview.totalMovimentos,
      totalCountLabel: 'movimentos',
    );
  }
}

class _MovimentacoesResultsPane extends ConsumerWidget {
  const _MovimentacoesResultsPane({
    required this.listState,
  });

  final MovimentacaoListState listState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.spacing;
    final notifier = ref.read(movimentacaoListProvider.notifier);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: switch (listState.viewState) {
        MovimentacaoViewState.loading => const MovimentacoesLoadingSkeleton(),
        MovimentacaoViewState.updating => Stack(
          children: [
            MovimentacoesTable(items: listState.items),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(minHeight: s.xxs),
            ),
          ],
        ),
        MovimentacaoViewState.error => MovimentacoesErrorState(
          message: listState.errorMessage ?? 'Falha ao carregar movimentos.',
          onRetry: notifier.refresh,
        ),
        MovimentacaoViewState.empty => MovimentacoesEmptyState(
          onClearFilters: listState.query.hasFilters
              ? notifier.clearFilters
              : null,
        ),
        _ => MovimentacoesTable(items: listState.items),
      },
    );
  }
}
