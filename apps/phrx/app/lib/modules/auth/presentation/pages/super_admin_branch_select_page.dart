import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/auth_session_notifier.dart';
import '../../../../app/providers/session_access_notifier.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/errors/api_failure.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/extensions.dart';
import '../../../../shared/layouts/auth_layout.dart';
import '../../../../shared/widgets/inputs/enterprise_search_field.dart';
import '../../../../shared/widgets/navigation/app_nav_config.dart';
import '../../../central/data/datasources/platform_admin_datasource.dart';
import '../../../central/domain/entities/platform_entities.dart';

/// Selecção de branch para Super Admin (API da plataforma + busca por tenant).
class SuperAdminBranchSelectPage extends ConsumerStatefulWidget {
  const SuperAdminBranchSelectPage({super.key});

  @override
  ConsumerState<SuperAdminBranchSelectPage> createState() =>
      _SuperAdminBranchSelectPageState();
}

class _SuperAdminBranchSelectPageState
    extends ConsumerState<SuperAdminBranchSelectPage> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<PlatformBranchListItem> _items = const [];
  bool _loading = true;
  String? _error;
  String? _enteringBranchId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({String? q}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref.read(platformAdminDataSourceProvider).fetchBranchesPage(
            page: 1,
            pageSize: 100,
            q: q,
            includeInactive: false,
          );
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _loading = false;
      });
    } on ApiFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      _load(q: value.trim().isEmpty ? null : value.trim());
    });
  }

  Future<void> _enterBranch(PlatformBranchListItem item) async {
    setState(() => _enteringBranchId = item.branch.id);
    try {
      await ref.read(authSessionProvider.notifier).selectTenantBranch(
            tenantId: item.tenantId,
            branchId: item.branch.id,
          );
      await ref.read(sessionAccessProvider.notifier).refresh();
      if (!mounted) return;
      context.go(homePathForAccess(ref.read(sessionAccessProvider)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _enteringBranchId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível entrar na filial: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final session = ref.watch(authSessionProvider).session;

    return AuthLayout(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Seleccionar branch/filial',
              style: Theme.of(context).textTheme.erpSectionTitle,
            ),
            SizedBox(height: s.sm),
            Text(
              'Olá, ${session?.user.name ?? 'Super Admin'}. '
              'Pesquise por tenant para filtrar as branches.',
              style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                    color: t.textMuted,
                  ),
            ),
            SizedBox(height: s.lg),
            EnterpriseSearchField(
              controller: _searchCtrl,
              hintText: 'Pesquisar tenant, filial ou código…',
              onChanged: _onSearchChanged,
            ),
            SizedBox(height: s.lg),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: s.lg),
                child: Column(
                  children: [
                    Text(
                      _error!,
                      style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                            color: t.posDanger,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: s.md),
                    TextButton(
                      onPressed: () => _load(
                        q: _searchCtrl.text.trim().isEmpty
                            ? null
                            : _searchCtrl.text.trim(),
                      ),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              )
            else if (_items.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: s.xxl),
                child: Text(
                  'Nenhuma branch encontrada.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.erpBodySecondary.copyWith(
                        color: t.textMuted,
                      ),
                ),
              )
            else
              for (final item in _items)
                Padding(
                  padding: EdgeInsets.only(bottom: s.sm),
                  child: Material(
                    color: t.card,
                    borderRadius: BorderRadius.circular(t.radiusMd),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(t.radiusMd),
                      onTap: _enteringBranchId != null
                          ? null
                          : () => _enterBranch(item),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: s.lg,
                          vertical: s.md,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(t.radiusMd),
                          border: Border.all(
                            color: t.border.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.store_outlined, color: t.brandGreen),
                            SizedBox(width: s.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.branch.code} — ${item.branch.name}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .erpLabel
                                        .copyWith(color: t.textPrimary),
                                  ),
                                  SizedBox(height: s.xxs),
                                  Text(
                                    item.tenantName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .erpCaption
                                        .copyWith(color: t.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            if (_enteringBranchId == item.branch.id)
                              SizedBox(
                                width: t.iconMd,
                                height: t.iconMd,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: t.textMuted,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            SizedBox(height: s.lg),
            TextButton(
              onPressed: () => context.go(AppRoutePaths.authAccessSelection),
              child: const Text('Voltar à selecção de acesso'),
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
