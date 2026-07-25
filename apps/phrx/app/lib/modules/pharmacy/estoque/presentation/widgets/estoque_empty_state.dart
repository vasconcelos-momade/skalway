import 'package:flutter/material.dart';

import '../../../../../shared/widgets/feedback/module_data_states.dart';

class EstoqueEmptyState extends StatelessWidget {
  const EstoqueEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModuleEmptyState(
      title: 'Nenhum lote encontrado',
      subtitle: 'Ajuste a pesquisa ou os filtros para ver resultados.',
    );
  }
}
