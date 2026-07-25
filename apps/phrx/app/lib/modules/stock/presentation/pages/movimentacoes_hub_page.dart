import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/navigation/app_nav_config.dart';
import '../providers/movimentacao_provider.dart';
import '../widgets/movimentacoes_body.dart';

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
    final listState = ref.watch(movimentacaoListProvider);

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

    return EnterpriseModuleHub(
      title: 'Movimentos de stock',
      subtitle: 'Entradas, saídas, ajustes e trilho de auditoria.',
      tag: AppNavSections.pharmacy,
      actions: [],
      child: Column(
        children: [
          Expanded(
            child: MovimentacoesBody(
              searchController: _searchController,
              listState: listState,
            ),
          ),
        ],
      ),
    );
  }
}
