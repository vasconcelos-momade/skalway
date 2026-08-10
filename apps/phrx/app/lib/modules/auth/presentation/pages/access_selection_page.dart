import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/auth_session_notifier.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/layouts/auth_layout.dart';

/// Pós-login do Super Admin: Plataforma Central vs Branch/Filial.
class AccessSelectionPage extends ConsumerWidget {
  const AccessSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final session = ref.watch(authSessionProvider).session;
    final name = session?.user.name ?? 'Super Admin';

    return AuthLayout(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Seleccionar acesso',
              style: Theme.of(context).textTheme.erpSectionTitle,
            ),
            SizedBox(height: s.sm),
            Text(
              'Olá, $name. Escolha onde pretende trabalhar.',
              style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                    color: t.textMuted,
                  ),
            ),
            SizedBox(height: s.xxl),
            _AccessCard(
              icon: Icons.admin_panel_settings_outlined,
              title: 'PhRx Plataforma',
              subtitle:
                  'Administração da base central: tenants, planos, facturação e utilizadores.',
              onTap: () => context.go(AppRoutePaths.platformDashboard),
            ),
            SizedBox(height: s.md),
            _AccessCard(
              icon: Icons.storefront_outlined,
              title: 'Branch / Filial',
              subtitle:
                  'Pesquisar um tenant e entrar numa branch/filial para administrar o PhRx operacional.',
              onTap: () => context.go(AppRoutePaths.authBranchSelection),
            ),
            SizedBox(height: s.xl),
            TextButton(
              onPressed: () async {
                await ref.read(authSessionProvider.notifier).signOut();
                if (context.mounted) context.go(AppRoutePaths.login);
              },
              child: const Text('Terminar sessão'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Material(
      color: t.card,
      borderRadius: BorderRadius.circular(t.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(t.radiusMd),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(s.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(t.radiusMd),
            border: Border.all(color: t.border.withValues(alpha: 0.6)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: t.brandGreen, size: t.iconMd),
              SizedBox(width: s.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.erpCardTitle.copyWith(
                            color: t.textPrimary,
                          ),
                    ),
                    SizedBox(height: s.xs),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                            color: t.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: t.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
