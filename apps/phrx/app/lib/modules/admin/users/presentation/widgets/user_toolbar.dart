import 'package:flutter/material.dart';

import '../../../../../shared/widgets/layout/enterprise_mobile_toolbar.dart';
import '../providers/user_list_provider.dart';

class UserMobileToolbar extends StatelessWidget {
  const UserMobileToolbar({
    super.key,
    required this.searchController,
    required this.state,
    required this.onSearchChanged,
    required this.onRefresh,
    this.reportAction,
  });

  final TextEditingController searchController;
  final UserListState state;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRefresh;
  final Widget? reportAction;

  @override
  Widget build(BuildContext context) {
    return EnterpriseMobileToolbar(
      searchController: searchController,
      searchHint: 'Nome ou email...',
      enabled: !state.isBusy,
      isLoading: state.isBusy,
      hasFilters: false,
      onSearchSubmitted: onSearchChanged,
      onOpenFilters: () {},
      onRefresh: onRefresh,
      reportAction: reportAction,
      showFiltersButton: false,
    );
  }
}
