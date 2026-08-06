import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../../shared/widgets/menus/enterprise_actions_menu_button.dart';
import '../../../../../shared/widgets/menus/enterprise_dropdown_menu.dart';
import '../../domain/entities/user_entities.dart';

class UserCard extends StatelessWidget {
  const UserCard({
    super.key,
    required this.user,
    required this.onTap,
    required this.onAction,
  });

  final TenantUserSummary user;
  final VoidCallback onTap;
  final void Function(String action) onAction;

  static final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

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
      ],
      trailingMeta: EnterpriseListCardMeta(
        label: 'Registo: ${_dateFmt.format(user.createdAt)}',
      ),
      onTap: null,
      actions: EnterpriseActionsMenuButton<String>(
        compact: true,
        items: [
          const EnterpriseDropdownItem(
            value: 'details',
            label: 'Detalhes',
            icon: Icons.visibility_outlined,
          ),
          const EnterpriseDropdownItem(
            value: 'edit',
            label: 'Editar',
            icon: Icons.edit_outlined,
          ),
          EnterpriseDropdownItem(
            value: 'toggle',
            label: active ? 'Desactivar' : 'Activar',
            icon: active
                ? Icons.person_off_outlined
                : Icons.person_outline,
            destructive: active,
          ),
        ],
        onSelected: onAction,
      ),
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
