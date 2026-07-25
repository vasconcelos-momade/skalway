import 'package:flutter/material.dart';

import '../../../../../shared/widgets/feedback/module_data_states.dart';

class ProdutoEmptyState extends StatelessWidget {
  const ProdutoEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModuleEmptyState(
      title: 'Nenhum produto encontrado',
      subtitle: 'Ajuste os filtros ou crie um novo produto.',
    );
  }
}
