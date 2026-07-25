import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/auth_session_notifier.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';

class SyncSettingsPage extends ConsumerWidget {
  const SyncSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final tenant = ref.watch(authSessionProvider).session?.selectedTenant;

    return EnterpriseModuleHub(
      title: 'Sincronização híbrida',
      subtitle: 'Backoff, batch size, WebSocket e política de conflitos.',
      tag: 'Sistema',
      child: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.cloud_sync_outlined, color: t.brandBlue),
            title: Text(
              'Entidade',
              style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.textPrimary),
            ),
            subtitle: Text(
              tenant?.companyName ?? '—',
              style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
            ),
          ),
          Divider(color: t.border.withValues(alpha: 0.35)),
          ListTile(
            leading: Icon(Icons.sync, color: t.brandGreen),
            title: Text(
              'Sincronização central',
              style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.textPrimary),
            ),
            subtitle: Text(
              'A sincronização entre a unidade e a plataforma central é gerida pelo backend. '
              'O POS mantém operação local com reconciliação automática quando a ligação é restabelecida.',
              style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
            ),
          ),
          ListTile(
            leading: Icon(Icons.schedule, color: t.brandBlue),
            title: Text(
              'Política de conflitos',
              style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.textPrimary),
            ),
            subtitle: Text(
              'Conflitos de stock e vendas são resolvidos pelo motor de sincronização do tenant.',
              style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
