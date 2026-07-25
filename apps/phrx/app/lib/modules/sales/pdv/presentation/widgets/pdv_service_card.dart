import 'package:flutter/material.dart';

import '../../../../../core/theme/design_metrics.dart';
import '../../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../domain/entities/pdv_service.dart';
import 'pdv_catalog_utils.dart';

class PdvServiceCard extends StatelessWidget {
  const PdvServiceCard({
    super.key,
    required this.service,
    required this.canAdd,
    required this.onAdd,
    this.compactAction = false,
  });

  final PdvService service;
  final bool canAdd;
  final VoidCallback onAdd;
  final bool compactAction;

  @override
  Widget build(BuildContext context) {
    return EnterpriseListCard(
      title: service.nome,
      subtitle: (service.tipoServicoClinico ?? '').isNotEmpty
          ? service.tipoServicoClinico
          : null,
      leading: Icons.medical_services_outlined,
      metadata: [
        EnterpriseListCardMeta(
          label:
              'PV ${pdvFormatMoney(service.preco)} • ${service.tipoServicoClinico ?? '—'}',
        ),
      ],
      onTap: canAdd ? onAdd : null,
      actions: SizedBox(
        height: DesignMetrics.buttonHeight,
        child: FilledButton(
          onPressed: canAdd ? onAdd : null,
          child: Text(compactAction ? '+' : 'Add'),
        ),
      ),
    );
  }
}
