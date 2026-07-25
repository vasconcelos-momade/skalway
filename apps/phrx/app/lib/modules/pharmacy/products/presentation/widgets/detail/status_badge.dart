import 'package:flutter/material.dart';

import '../../../../../../core/theme/design_tokens.dart';
import '../../../../../../shared/widgets/cards/enterprise_list_card.dart';

/// Badge de estado activo/inactivo.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final color = active ? t.brandGreen : t.posDanger;
    final label = active ? 'Activo' : 'Inactivo';

    return EnterpriseStatusChip(label: label, color: color);
  }
}
