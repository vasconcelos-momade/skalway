import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../domain/entities/user_entities.dart';

class UserCard extends StatelessWidget {
  const UserCard({
    super.key,
    required this.user,
    required this.onTap,
  });

  final TenantUserSummary user;
  final VoidCallback onTap;

  static final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final active = user.active;

    return EnterpriseListCard(
      title: user.name,
      subtitle: user.email,
      leading: Icons.person_outline,
      chip: EnterpriseStatusChip(
        label: active ? 'Activo' : 'Inactivo',
        color: active ? t.brandGreen : t.posDanger,
      ),
      metadata: [
        EnterpriseListCardMeta(label: _roleLabel(user.role), color: t.brandBlue),
        EnterpriseListCardMeta(label: 'Registo: ${_dateFmt.format(user.createdAt)}'),
      ],
      onTap: onTap,
    );
  }

  String _roleLabel(String role) => switch (role) {
        'ADMIN' => 'Administrador',
        'GERENTE' => 'Gestor',
        'FARMACEUTICO' => 'Farmacêutico',
        'DIRETOR_TECNICO' => 'Director técnico',
        'CAIXA' => 'Caixa PDV',
        _ => role,
      };
}
