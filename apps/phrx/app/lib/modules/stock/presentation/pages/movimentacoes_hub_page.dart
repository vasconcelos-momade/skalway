import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/refresh/page_refresh.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../providers/movimentacao_provider.dart';
import '../widgets/movimentacoes_body.dart';
import '../widgets/movimentacoes_overview_cards.dart';
import '../widgets/movimentacoes_toolbar.dart';

class MovimentacoesHubPage extends ConsumerStatefulWidget {
  const MovimentacoesHubPage({super.key});

  @override
  ConsumerState<MovimentacoesHubPage> createState() =>
      _MovimentacoesHubPageState();
}

class _MovimentacoesHubPageState extends ConsumerState<MovimentacoesHubPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(movimentacaoListProvider).query.search,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final listState = ref.watch(movimentacaoListProvider);
    final notifier = ref.read(movimentacaoListProvider.notifier);

    ref.listen<MovimentacaoListState>(movimentacaoListProvider, (
      previous,
      next,
    ) {
      if (_searchController.text != next.query.search) {
        _searchController.value = TextEditingValue(
          text: next.query.search,
          selection: TextSelection.collapsed(offset: next.query.search.length),
        );
      }
    });

    final kpiCards = MovimentacoesOverviewCards.buildCards(
      overview: listState.overview,
      hasFilters: listState.query.hasFilters,
    );

    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = !constraints.isTabletOrWider;

        return PageRefreshBinder(
          onRefresh: notifier.refresh,
          child: Scaffold(
            backgroundColor: t.bgPrimary,
            body: EnterpriseModuleHub(
              title: 'Movimentos de stock',
              subtitle: 'Entradas, saídas, ajustes e trilho de auditoria.',
              mobileKpisHorizontalScroll: true,
              kpis: isMobile ? null : kpiCards,
              filters: isMobile
                  ? null
                  : MovimentacoesToolbar(
                      searchController: _searchController,
                      state: listState,
                    ),
              child: MovimentacoesBody(
                searchController: _searchController,
                listState: listState,
              ),
            ),
          ),
        );
      },
    );
  }
}
