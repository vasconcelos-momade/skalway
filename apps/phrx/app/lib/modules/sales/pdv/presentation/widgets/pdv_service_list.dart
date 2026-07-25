import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../../shared/widgets/feedback/module_data_states.dart';
import '../../domain/entities/pdv_service.dart';
import 'pdv_service_card.dart';

class PdvServiceList extends StatelessWidget {
  const PdvServiceList({
    super.key,
    required this.items,
    required this.query,
    required this.canAdd,
    required this.onAdd,
    this.bottomPadding = 0,
  });

  final List<PdvService> items;
  final String query;
  final bool canAdd;
  final void Function(PdvService service) onAdd;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    if (items.isEmpty) {
      return ModuleEmptyState(
        title: query.isEmpty
            ? 'Nenhum serviço disponível.'
            : 'Nenhum serviço encontrado.',
        subtitle: query.isEmpty ? null : 'Tente outro nome de serviço.',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(bottom: bottomPadding + s.md),
      itemCount: items.length,
      separatorBuilder: (_, _) => const EnterpriseListDivider(),
      itemBuilder: (context, index) {
        final service = items[index];
        return PdvServiceCard(
          service: service,
          canAdd: canAdd,
          onAdd: () => onAdd(service),
          compactAction: true,
        );
      },
    );
  }
}
