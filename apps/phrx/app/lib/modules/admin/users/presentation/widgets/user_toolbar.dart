import 'package:flutter/material.dart';

import '../../../../../shared/widgets/inputs/enterprise_select_field.dart';
import '../../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../../../../../shared/widgets/tables/enterprise_table_filter_panel.dart';
import '../providers/user_list_provider.dart';

class UserMobileToolbar extends StatelessWidget {
  const UserMobileToolbar({
    super.key,
    required this.searchController,
    required this.state,
    required this.notifier,
    required this.onSearchChanged,
    required this.onRefresh,
    this.reportAction,
  });

  final TextEditingController searchController;
  final UserListState state;
  final UserListController notifier;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRefresh;
  final Widget? reportAction;

  bool get _hasTableFilters =>
      state.query.role != null || state.query.active != null;

  @override
  Widget build(BuildContext context) {
    return EnterpriseMobileToolbar(
      searchController: searchController,
      searchHint: 'Nome ou email...',
      enabled: !state.isBusy,
      isLoading: state.isBusy,
      hasFilters: _hasTableFilters,
      onSearchSubmitted: onSearchChanged,
      onOpenFilters: () => _openFilters(context),
      onRefresh: onRefresh,
      onClearFilters: _hasTableFilters
          ? () async {
              await notifier.setRoleFilter(null);
              await notifier.setActiveFilter(null);
            }
          : null,
      reportAction: reportAction,
      showFiltersButton: true,
    );
  }

  void _openFilters(BuildContext context) {
    EnterpriseTableFilterPanel.present(
      context: context,
      title: 'Filtros',
      filters: userTableFilterFields(
        state: state,
        notifier: notifier,
      ),
      onClear: () async {
        await notifier.setRoleFilter(null);
        await notifier.setActiveFilter(null);
      },
      onApply: () {},
    );
  }
}

/// Campos partilhados do painel de filtros (desktop dropdown / mobile sheet).
List<Widget> userTableFilterFields({
  required UserListState state,
  required UserListController notifier,
}) {
  return [
    EnterpriseSelectField<String>(
      key: ValueKey('user-filter-role-${state.query.role}'),
      label: 'Perfil',
      emptyLabel: 'Todos',
      value: state.query.role,
      options: const [
        EnterpriseSelectOption(value: 'ADMIN', label: 'Administrador'),
        EnterpriseSelectOption(value: 'GERENTE', label: 'Gestor'),
        EnterpriseSelectOption(value: 'FARMACEUTICO', label: 'Farmacêutico'),
        EnterpriseSelectOption(
          value: 'DIRETOR_TECNICO',
          label: 'Director técnico',
        ),
        EnterpriseSelectOption(value: 'CAIXA', label: 'Caixa PDV'),
      ],
      onChanged: state.isBusy ? null : notifier.setRoleFilter,
    ),
    EnterpriseSelectField<bool>(
      key: ValueKey('user-filter-active-${state.query.active}'),
      label: 'Estado',
      emptyLabel: 'Todos',
      value: state.query.active,
      options: const [
        EnterpriseSelectOption(value: true, label: 'Activos'),
        EnterpriseSelectOption(value: false, label: 'Inactivos'),
      ],
      onChanged: state.isBusy ? null : notifier.setActiveFilter,
    ),
  ];
}
