import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/widgets/cards/enterprise_list_card.dart';
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

  static final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
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
      onTap: null, // Para interagir apenas via menu de ações
      actions: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          minWidth: t.minTouchTarget * 0.6,
          minHeight: t.minTouchTarget * 0.6,
        ),
        icon: Icon(Icons.more_vert, size: t.iconSm, color: t.textMuted),
        tooltip: 'Ações',
        onSelected: onAction,
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'details',
            child: Row(
              children: [
                Icon(Icons.visibility_outlined, size: t.iconSm, color: t.textPrimary),
                SizedBox(width: s.sm),
                Text(
                  'Detalhes',
                  style: Theme.of(context).textTheme.erpBody.copyWith(
                        color: t.textPrimary,
                      ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: t.iconSm, color: t.textPrimary),
                SizedBox(width: s.sm),
                Text(
                  'Editar',
                  style: Theme.of(context).textTheme.erpBody.copyWith(
                        color: t.textPrimary,
                      ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'toggle',
            child: Row(
              children: [
                Icon(
                  active ? Icons.person_off_outlined : Icons.person_outline,
                  size: t.iconSm,
                  color: active ? t.posDanger : t.textPrimary,
                ),
                SizedBox(width: s.sm),
                Text(
                  active ? 'Desactivar' : 'Activar',
                  style: Theme.of(context).textTheme.erpBody.copyWith(
                        color: active ? t.posDanger : t.textPrimary,
                      ),
                ),
              ],
            ),
          ),
        ],
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
