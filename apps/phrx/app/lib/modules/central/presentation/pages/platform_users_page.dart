import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/elevation_tokens.dart';
import '../../../../shared/refresh/page_refresh.dart';
import '../../../../shared/responsive/responsive_builder.dart';
import '../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../../shared/widgets/feedback/module_data_states.dart';
import '../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_scroll_list.dart';
import '../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../../../shared/widgets/layout/enterprise_module_hub.dart';
import '../../../../shared/widgets/menus/enterprise_actions_menu_button.dart';
import '../../../../shared/widgets/menus/enterprise_dropdown_menu.dart';
import '../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../../../shared/widgets/tables/enterprise_pagination.dart';
import '../../domain/entities/platform_entities.dart';
import '../providers/platform_providers.dart';
import '../widgets/platform_user_form_side_sheet.dart';

class PlatformUsersPage extends ConsumerStatefulWidget {
  const PlatformUsersPage({super.key});

  @override
  ConsumerState<PlatformUsersPage> createState() => _PlatformUsersPageState();
}

class _PlatformUsersPageState extends ConsumerState<PlatformUsersPage> {
  final _searchCtrl = TextEditingController();
  final List<PlatformUser> _accumulated = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(platformUsersProvider);
    final busy = ref.watch(platformBillingActionsProvider);
    final notifier = ref.read(platformUsersProvider.notifier);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    if (_searchCtrl.text != notifier.search) {
      _searchCtrl.value = TextEditingValue(
        text: notifier.search,
        selection: TextSelection.collapsed(offset: notifier.search.length),
      );
    }

    ref.listen(platformUsersProvider, (previous, next) {
      final data = next.asData?.value;
      if (data == null) return;
      final prevData = previous?.asData?.value;
      if (data.page == 1) {
        _accumulated
          ..clear()
          ..addAll(data.items);
      } else if (prevData?.page != data.page) {
        _accumulated.addAll(
          data.items.where((e) => !_accumulated.any((a) => a.id == e.id)),
        );
      }
    });

    final pageData = async.asData?.value;
    if (pageData != null &&
        pageData.page == 1 &&
        _accumulated.isEmpty &&
        pageData.items.isNotEmpty) {
      _accumulated.addAll(pageData.items);
    }

    return ResponsiveBuilder(
      builder: (context, constraints) {
        final isMobile = !constraints.isTabletOrWider;

        return PageRefreshBinder(
          onRefresh: () => notifier.refresh(),
          child: Scaffold(
            backgroundColor: context.pharmaTokens.bgPrimary,
            floatingActionButton: isMobile
                ? FloatingActionButton(
                    onPressed: busy ? null : () => _create(context),
                    backgroundColor: context.pharmaTokens.brandBlue,
                    foregroundColor: Colors.white,
                    elevation:
                        Theme.of(context).extension<ElevationTokens>()?.level3 ??
                            3.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        context.pharmaTokens.radiusLg,
                      ),
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded),
                  )
                : null,
            body: EnterpriseModuleHub(
              title: 'Utilizadores',
              subtitle: 'SuperAdmins e operadores da plataforma central.',
              tag: 'Plataforma',
              actions: isMobile
                  ? null
                  : [
                      FilledButton.icon(
                        onPressed: busy ? null : () => _create(context),
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Novo utilizador'),
                      ),
                    ],
              child: async.when(
                loading: () => _accumulated.isEmpty
                    ? const ModuleLoadingState()
                    : _buildBody(
                        context,
                        isMobile: isMobile,
                        users: _accumulated,
                        page: pageData?.page ?? notifier.page,
                        pageSize: pageData?.pageSize ?? notifier.pageSize,
                        hasMore: pageData?.hasMore ?? false,
                        totalCount: pageData?.totalCount,
                        isLoading: true,
                        busy: busy,
                        dateFmt: dateFmt,
                        notifier: notifier,
                      ),
                error: (e, _) => _accumulated.isEmpty
                    ? ModuleErrorState(
                        title: 'Erro ao carregar utilizadores',
                        message: e.toString(),
                        onRetry: () => notifier.refresh(),
                      )
                    : _buildBody(
                        context,
                        isMobile: isMobile,
                        users: _accumulated,
                        page: notifier.page,
                        pageSize: notifier.pageSize,
                        hasMore: false,
                        totalCount: null,
                        isLoading: false,
                        errorText: e.toString(),
                        busy: busy,
                        dateFmt: dateFmt,
                        notifier: notifier,
                      ),
                data: (page) => _buildBody(
                  context,
                  isMobile: isMobile,
                  users: isMobile ? _accumulated : page.items,
                  page: page.page,
                  pageSize: page.pageSize,
                  hasMore: page.hasMore,
                  totalCount: page.totalCount,
                  isLoading: false,
                  busy: busy,
                  dateFmt: dateFmt,
                  notifier: notifier,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required bool isMobile,
    required List<PlatformUser> users,
    required int page,
    required int pageSize,
    required bool hasMore,
    required int? totalCount,
    required bool isLoading,
    required bool busy,
    required DateFormat dateFmt,
    required PlatformUsersNotifier notifier,
    String? errorText,
  }) {
    return EnterpriseAdaptiveListBody(
      isMobile: isMobile,
      isLoading: isLoading,
      errorText: errorText,
      desktopContent: EnterpriseDataTable(
        adaptive: false,
        showCheckboxColumn: false,
        searchController: _searchCtrl,
        searchHint: 'Pesquisar nome ou email…',
        onSearchChanged: notifier.setSearch,
        isLoading: isLoading,
        errorMessage: errorText,
        errorTitle: 'Erro ao carregar utilizadores',
        onRetry: () => notifier.refresh(),
        emptyTitle: 'Sem utilizadores.',
        columns: const [
          DataColumn(label: Text('Nome')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Perfil')),
          DataColumn(label: Text('Activo')),
          DataColumn(label: Text('Último Login')),
          DataColumn(label: Text('Data de Criação')),
          DataColumn(label: Text('Acções')),
        ],
        rowCount: users.length,
        rowBuilder: (context, index) {
          final user = users[index];
          return DataRow(
            cells: [
              DataCell(Text(user.name)),
              DataCell(Text(user.email)),
              DataCell(Text(_roleLabel(user.role))),
              DataCell(
                EnterpriseStatusChip(
                  label: user.active ? 'Activo' : 'Inactivo',
                  color: user.active
                      ? context.pharmaTokens.posSuccess
                      : context.pharmaTokens.textMuted,
                ),
              ),
              DataCell(
                Text(
                  user.lastLoginAt == null
                      ? '—'
                      : dateFmt.format(user.lastLoginAt!.toLocal()),
                ),
              ),
              DataCell(
                Text(
                  user.createdAt == null
                      ? '—'
                      : dateFmt.format(user.createdAt!.toLocal()),
                ),
              ),
              DataCell(_UserActionsMenu(user: user, busy: busy)),
            ],
          );
        },
        pagination: totalCount != null
            ? EnterprisePagination(
                page: page,
                pageSize: pageSize,
                totalCount: totalCount,
                isBusy: isLoading,
                itemLabel: 'utilizadores',
                onPageChanged: notifier.goToPage,
                onPageSizeChanged: notifier.setPageSize,
              )
            : null,
      ),
      mobileList: EnterpriseMobileScrollList(
        stickyHeader: EnterpriseMobileToolbar(
          searchController: _searchCtrl,
          searchHint: 'Pesquisar nome ou email…',
          enabled: !isLoading,
          isLoading: isLoading,
          hasFilters: false,
          showFiltersButton: false,
          onSearchSubmitted: notifier.setSearch,
          onOpenFilters: () {},
        ),
        itemCount: users.length,
        hasMore: hasMore,
        isLoading: isLoading,
        emptyMessage: 'Sem utilizadores.',
        onLoadMore:
            hasMore && !isLoading ? () => notifier.goToPage(page + 1) : null,
        itemBuilder: (context, index) {
          final user = users[index];
          return Column(
            children: [
              if (index > 0) const EnterpriseListDivider(),
              EnterpriseListCard(
                title: user.name,
                subtitle: user.email,
                chip: EnterpriseStatusChip(
                  label: user.active ? 'Activo' : 'Inactivo',
                  color: user.active
                      ? context.pharmaTokens.posSuccess
                      : context.pharmaTokens.textMuted,
                ),
                actions: _UserActionsMenu(user: user, busy: busy),
                metadata: [
                  EnterpriseListCardMeta(label: _roleLabel(user.role)),
                  EnterpriseListCardMeta(
                    label: user.lastLoginAt == null
                        ? 'Sem login'
                        : dateFmt.format(user.lastLoginAt!.toLocal()),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    final payload = await showPlatformUserFormSideSheet(context);
    if (payload == null || !context.mounted) return;
    if (payload.password == null || payload.password!.isEmpty) {
      PharmaFeedback.error(context, 'Password é obrigatória.');
      return;
    }
    try {
      await ref.read(platformBillingActionsProvider.notifier).createUser(payload);
      if (!context.mounted) return;
      PharmaFeedback.success(context, 'Utilizador criado.');
    } catch (e) {
      if (!context.mounted) return;
      PharmaFeedback.error(context, 'Erro: $e');
    }
  }
}

enum _UserAction { edit, activate, deactivate, resetPassword }

class _UserActionsMenu extends ConsumerWidget {
  const _UserActionsMenu({required this.user, required this.busy});

  final PlatformUser user;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EnterpriseActionsMenuButton<_UserAction>(
      enabled: !busy,
      items: [
        const EnterpriseDropdownItem(
          value: _UserAction.edit,
          label: 'Editar',
          icon: Icons.edit_outlined,
        ),
        const EnterpriseDropdownItem(
          value: _UserAction.resetPassword,
          label: 'Reset Password',
          icon: Icons.lock_reset_outlined,
        ),
        if (user.active)
          const EnterpriseDropdownItem(
            value: _UserAction.deactivate,
            label: 'Desactivar',
            icon: Icons.person_off_outlined,
            destructive: true,
          )
        else
          const EnterpriseDropdownItem(
            value: _UserAction.activate,
            label: 'Activar',
            icon: Icons.person_outline,
          ),
      ],
      onSelected: (action) async {
        final notifier = ref.read(platformBillingActionsProvider.notifier);
        try {
          switch (action) {
            case _UserAction.edit:
              final payload =
                  await showPlatformUserFormSideSheet(context, user: user);
              if (payload == null || !context.mounted) return;
              await notifier.updateUser(userId: user.id, payload: payload);
              if (!context.mounted) return;
              PharmaFeedback.success(context, 'Utilizador actualizado.');
            case _UserAction.resetPassword:
              final payload = await showPlatformUserFormSideSheet(
                context,
                user: user,
                resetPasswordOnly: true,
              );
              if (payload?.password == null || !context.mounted) return;
              await notifier.resetUserPassword(
                userId: user.id,
                password: payload!.password!,
              );
              if (!context.mounted) return;
              PharmaFeedback.success(context, 'Password redefinida.');
            case _UserAction.activate:
              await notifier.setUserActive(userId: user.id, active: true);
              if (!context.mounted) return;
              PharmaFeedback.success(context, 'Utilizador activado.');
            case _UserAction.deactivate:
              final ok = await PharmaFeedback.confirm(
                context: context,
                title: 'Desactivar utilizador',
                message: 'Desactivar ${user.name}?',
                confirmText: 'Desactivar',
                destructive: true,
              );
              if (!ok || !context.mounted) return;
              await notifier.setUserActive(userId: user.id, active: false);
              if (!context.mounted) return;
              PharmaFeedback.success(context, 'Utilizador desactivado.');
          }
        } catch (e) {
          if (!context.mounted) return;
          PharmaFeedback.error(context, 'Erro: $e');
        }
      },
    );
  }
}

String _roleLabel(String role) {
  switch (role.toLowerCase()) {
    case 'superadmin':
      return 'SuperAdmin';
    case 'admin':
      return 'Admin';
    case 'usuario':
      return 'Utilizador';
    default:
      return role;
  }
}
