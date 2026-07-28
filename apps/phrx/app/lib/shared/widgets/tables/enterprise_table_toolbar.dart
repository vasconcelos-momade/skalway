import 'package:flutter/material.dart';
import '../../../core/theme/extensions.dart';
import '../inputs/enterprise_search_field.dart';

class EnterpriseTableToolbar extends StatelessWidget {
  const EnterpriseTableToolbar({
    super.key,
    this.searchHint,
    this.searchController,
    this.onSearchChanged,
    this.toolbarActions,
    this.filterWidgets,
  });

  final String? searchHint;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final List<Widget>? toolbarActions;
  final List<Widget>? filterWidgets;

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;
    final hasSearch = searchController != null;
    final hasFilters = (filterWidgets != null && filterWidgets!.isNotEmpty);
    final hasActions = (toolbarActions != null && toolbarActions!.isNotEmpty);

    if (!hasSearch && !hasFilters && !hasActions) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.all(s.md),
      child: Wrap(
        spacing: s.md,
        runSpacing: s.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          if (hasSearch)
            SizedBox(
              width: 320, // Define largura máxima para o search field
              child: EnterpriseSearchField(
                controller: searchController!,
                hintText: searchHint ?? 'Pesquisar...',
                onChanged: onSearchChanged ?? (_) {},
              ),
            ),
          if (hasFilters || hasActions)
            Wrap(
              spacing: s.md,
              runSpacing: s.md,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (hasFilters) ...filterWidgets!,
                if (hasActions) ...toolbarActions!,
              ],
            ),
        ],
      ),
    );
  }
}
