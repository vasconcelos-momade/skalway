import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/auth_session_notifier.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final session = ref.watch(authSessionProvider).session;
    final tenant = session?.selectedTenant;
    final branch = session?.selectedBranch;
    final user = session?.user;

    return EnterpriseModuleHub(
      title: 'Definições gerais',
      subtitle: 'Entidade, idioma, moeda e políticas de sessão.',
      tag: 'Sistema',
      child: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.person_outline, color: t.brandBlue),
            title: Text(
              'Utilizador',
              style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.textPrimary),
            ),
            subtitle: Text(
              user == null ? '—' : '${user.name} (${user.email})',
              style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
            ),
          ),
          Divider(color: t.border.withValues(alpha: 0.35)),
          ListTile(
            leading: Icon(Icons.business, color: t.brandBlue),
            title: Text(
              'Unidade activa',
              style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.textPrimary),
            ),
            subtitle: Text(
              tenant == null
                  ? 'Nenhuma entidade seleccionada'
                  : '${tenant.companyName} • ${branch?.name ?? '—'}',
              style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
            ),
            trailing: TextButton(
              onPressed: () => context.go(AppRoutePaths.authTenant),
              child: const Text('Alterar'),
            ),
          ),
          Divider(color: t.border.withValues(alpha: 0.35)),
          ListTile(
            leading: Icon(Icons.print_outlined, color: t.brandGreen),
            title: Text(
              'Impressoras',
              style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.textPrimary),
            ),
            subtitle: Text(
              'Configuração térmica ESC/POS',
              style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutePaths.settingsPrinters),
          ),
          ListTile(
            leading: Icon(Icons.point_of_sale_outlined, color: t.brandGreen),
            title: Text(
              'Terminais & PDV',
              style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.textPrimary),
            ),
            subtitle: Text(
              'Caixas e terminais registados',
              style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutePaths.settingsTerminals),
          ),
          ListTile(
            leading: Icon(Icons.sync, color: t.brandGreen),
            title: Text(
              'Sincronização',
              style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.textPrimary),
            ),
            subtitle: Text(
              'Política híbrida e fila offline',
              style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutePaths.settingsSync),
          ),
        ],
      ),
    );
  }
}
