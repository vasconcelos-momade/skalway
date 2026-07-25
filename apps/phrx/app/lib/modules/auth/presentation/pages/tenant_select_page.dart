import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/auth_session_notifier.dart';
import '../../../../app/providers/connection_notifier.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/network/connectivity/connection_mode.dart';
import '../../../../core/network/connectivity/connection_status.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../domain/entities/branch_access.dart';
import '../../domain/entities/tenant_access.dart';
import '../../../../shared/layouts/auth_layout.dart';

class TenantSelectPage extends ConsumerStatefulWidget {
  const TenantSelectPage({super.key});

  @override
  ConsumerState<TenantSelectPage> createState() => _TenantSelectPageState();
}

class _TenantSelectPageState extends ConsumerState<TenantSelectPage> {
  String? _tenantId;
  String? _branchId;

  @override
  void initState() {
    super.initState();
    final session = ref.read(authSessionProvider).session;
    if (session != null) {
      if (session.isSuperAdmin) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(AppRoutePaths.platformDashboard);
        });
        return;
      }
      _tenantId = session.tenantId ?? _firstTenantId(session.tenants);
      _branchId = session.branchId ?? _firstBranchId(session.tenants, _tenantId);
    }
  }

  String? _firstTenantId(List<TenantAccess> tenants) =>
      tenants.isNotEmpty ? tenants.first.id : null;

  String? _firstBranchId(List<TenantAccess> tenants, String? tenantId) {
    if (tenantId == null) return null;
    for (final t in tenants) {
      if (t.id == tenantId && t.branches.isNotEmpty) {
        return t.branches.first.id;
      }
    }
    return null;
  }

  TenantAccess? get _selectedTenant {
    final session = ref.watch(authSessionProvider).session;
    if (session == null || _tenantId == null) return null;
    for (final t in session.tenants) {
      if (t.id == _tenantId) return t;
    }
    return null;
  }

  List<BranchAccess> get _branches => _selectedTenant?.branches ?? [];

  Future<void> _continue() async {
    if (_tenantId == null || _branchId == null) return;
    await ref.read(authSessionProvider.notifier).selectTenantBranch(
          tenantId: _tenantId!,
          branchId: _branchId!,
        );
    if (!mounted) return;
    context.go(AppRoutePaths.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final session = ref.watch(authSessionProvider).session;
    final connection = ref.watch(connectionNotifierProvider);
    final showConnectionBanner = connection.isOffline;
    final connectionMessage = switch (connection.status) {
      ConnectionStatus.offline =>
        'Sem ligação aos serviços disponíveis. A selecção continua local até a API voltar.',
      _ => null,
    };

    if (session == null) {
      return const AuthLayout(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (session.tenants.isEmpty) {
      return AuthLayout(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sem farmácias associadas a esta conta.',
              style: Theme.of(context).textTheme.erpCardTitle,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: () => context.go(AppRoutePaths.login),
              child: const Text('Voltar ao login'),
            ),
          ],
        ),
      );
    }

    return AuthLayout(
      showOfflineBanner: showConnectionBanner,
      offlineMessage: connectionMessage,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Seleccionar unidade',
              style: Theme.of(context).textTheme.erpSectionTitle,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Olá, ${session.user.name}. Escolha a farmácia e a unidade.',
              style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _TenantStatusChip(
                  icon: connection.mode == ConnectionMode.cloud
                      ? Icons.cloud_done_outlined
                      : Icons.lan_outlined,
                  label: connection.mode == ConnectionMode.cloud
                      ? 'Modo nuvem'
                      : 'Modo local',
                  color: connection.mode == ConnectionMode.cloud
                      ? t.brandGreenHover
                      : t.brandGreen,
                ),
                _TenantStatusChip(
                  icon: connection.status == ConnectionStatus.offline
                      ? Icons.cloud_off_outlined
                      : Icons.check_circle_outline_rounded,
                  label: connection.status == ConnectionStatus.offline
                      ? 'Offline'
                      : (connection.mode == ConnectionMode.cloud
                          ? 'Nuvem activa'
                          : 'Local activo'),
                  color: connection.status == ConnectionStatus.offline
                      ? t.posDanger
                      : t.brandGreen,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Organização',
              style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.textMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final tenant in session.tenants)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Material(
                  color: _tenantId == tenant.id
                      ? t.brandGreen.withValues(alpha: 0.1)
                      : t.card,
                  borderRadius: BorderRadius.circular(t.radiusMd),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(t.radiusMd),
                    onTap: () => setState(() {
                      _tenantId = tenant.id;
                      _branchId = tenant.branches.isNotEmpty
                          ? tenant.branches.first.id
                          : null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(t.radiusMd),
                        border: Border.all(color: t.border.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _tenantId == tenant.id
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: _tenantId == tenant.id ? t.brandGreen : t.textMuted,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tenant.companyName,
                                  style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.textPrimary),
                                ),
                                Text(
                                  tenant.name,
                                  style: Theme.of(context).textTheme.erpCaption.copyWith(color: t.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_branches.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Unidade',
                style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.textMuted),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final branch in _branches)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Material(
                    color: _branchId == branch.id
                        ? t.brandGreen.withValues(alpha: 0.12)
                        : t.card,
                    borderRadius: BorderRadius.circular(t.radiusMd),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(t.radiusMd),
                      onTap: () => setState(() => _branchId = branch.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(t.radiusMd),
                          border: Border.all(color: t.border.withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _branchId == branch.id
                                  ? Icons.store_rounded
                                  : Icons.store_outlined,
                              color: _branchId == branch.id ? t.brandGreen : t.textMuted,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                '${branch.code} — ${branch.name}',
                                style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _tenantId != null && _branchId != null ? _continue : null,
              child: const Text('Continuar'),
            ),
            if (ref.watch(authSessionProvider).session?.isSuperAdmin ?? false)
              TextButton(
                onPressed: () => context.go(AppRoutePaths.platformDashboard),
                child: const Text('Painel da plataforma SaaS'),
              ),
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

class _TenantStatusChip extends StatelessWidget {
  const _TenantStatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.erpLabel.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
