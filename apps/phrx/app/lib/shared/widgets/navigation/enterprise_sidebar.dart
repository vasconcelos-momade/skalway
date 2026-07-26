import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/nav_groups_collapsed_provider.dart';
import '../../../core/theme/design_metrics.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/dimensions.dart';
import '../../../core/theme/extensions.dart';
import 'app_nav_config.dart';

/// Sidebar desktop fixa (Notion / Linear / Slack / Fluent).
///
/// - Grupos com ícone + chevron (colapsáveis)
/// - Submenus só indentados (sem ícones / sem cards)
/// - Activo: barra lateral + fundo discreto
/// - Sem poluição visual (sem caixas, sombras ou UPPERCASE)
class EnterpriseSidebar extends StatelessWidget {
  const EnterpriseSidebar({
    super.key,
    required this.location,
    required this.sections,
    required this.onLogout,
  });

  final String location;
  final List<AppNavSection> sections;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;

    return SizedBox(
      width: AppDimensions.sidebarExpanded,
      child: Material(
        color: t.bgSecondary,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: t.border.withValues(alpha: 0.5)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EnterpriseNavBrand(),
              Expanded(
                child: EnterpriseNavMenu(
                  location: location,
                  sections: sections,
                  onSelect: (path) => context.go(path),
                ),
              ),
              EnterpriseNavLogout(onLogout: onLogout),
            ],
          ),
        ),
      ),
    );
  }
}

/// Marca minimalista (logo + nome).
class EnterpriseNavBrand extends StatelessWidget {
  const EnterpriseNavBrand({super.key, this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Padding(
      padding: EdgeInsets.fromLTRB(s.md, s.md, s.sm, s.sm),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(t.radiusSm),
            child: Image.asset(
              'assets/logos/logo_512.png',
              width: DesignMetrics.iconMd,
              height: DesignMetrics.iconMd,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: s.sm),
          Expanded(
            child: Text(
              'PhRx',
              style: Theme.of(context).textTheme.erpAppName.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Logout discreto (estilo Linear / Notion).
class EnterpriseNavLogout extends StatelessWidget {
  const EnterpriseNavLogout({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Padding(
      padding: EdgeInsets.fromLTRB(s.sm, s.xs, s.sm, s.md),
      child: _NavHoverTile(
        onTap: onLogout,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.sm),
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                size: DesignMetrics.iconSm,
                color: t.textMuted,
              ),
              SizedBox(width: s.sm),
              Expanded(
                child: Text(
                  'Encerrar sessão',
                  style: Theme.of(context).textTheme.erpMenuItem.copyWith(
                        color: t.textSecondary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Menu partilhado (sidebar + drawer).
class EnterpriseNavMenu extends ConsumerStatefulWidget {
  const EnterpriseNavMenu({
    super.key,
    required this.location,
    required this.sections,
    required this.onSelect,
    this.showSearch = true,
  });

  final String location;
  final List<AppNavSection> sections;
  final ValueChanged<String> onSelect;
  final bool showSearch;

  @override
  ConsumerState<EnterpriseNavMenu> createState() => _EnterpriseNavMenuState();
}

class _EnterpriseNavMenuState extends ConsumerState<EnterpriseNavMenu> {
  final _searchController = TextEditingController();
  late final ScrollController _scrollController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final next = _searchController.text.trim().toLowerCase();
    if (next == _query) return;
    setState(() => _query = next);
  }

  List<AppNavSection> get _filteredSections {
    if (_query.isEmpty) return widget.sections;
    final out = <AppNavSection>[];
    for (final group in widget.sections) {
      final items = group.items
          .where(
            (item) =>
                item.label.toLowerCase().contains(_query) ||
                group.title.toLowerCase().contains(_query),
          )
          .toList(growable: false);
      if (items.isNotEmpty) {
        out.add(
          AppNavSection(
            title: group.title,
            items: items,
            icon: group.icon,
          ),
        );
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final collapsed = ref.watch(navGroupsCollapsedProvider);
    final sections = _filteredSections;
    final searching = _query.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showSearch)
          Padding(
            padding: EdgeInsets.fromLTRB(s.sm, 0, s.sm, s.sm),
            child: _NavSearchField(controller: _searchController),
          ),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thickness: 4,
            radius: Radius.circular(t.radiusSm),
            child: ListView.builder(
              controller: _scrollController,
              primary: false,
              padding: EdgeInsets.fromLTRB(s.sm, 0, s.sm, s.md),
              itemCount: sections.isEmpty ? 1 : sections.length,
              itemBuilder: (context, index) {
                if (sections.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.all(s.md),
                    child: Text(
                      'Nenhum menu encontrado',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .erpCaption
                          .copyWith(color: t.textMuted),
                    ),
                  );
                }

                final group = sections[index];
                final isExpanded =
                    searching || !collapsed.contains(group.title);
                final groupActive = group.items.any(
                  (item) => item.path == widget.location,
                );

                return Padding(
                  padding: EdgeInsets.only(bottom: s.xs),
                  child: _NavGroup(
                    title: group.title,
                    icon: group.resolvedIcon,
                    expanded: isExpanded,
                    groupActive: groupActive,
                    onHeaderTap: searching
                        ? null
                        : () => ref
                            .read(navGroupsCollapsedProvider.notifier)
                            .toggle(group.title),
                    children: [
                      for (final item in group.items)
                        _NavLeafTile(
                          label: item.label,
                          active: widget.location == item.path,
                          onTap: () => widget.onSelect(item.path),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _NavSearchField extends StatelessWidget {
  const _NavSearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      style: theme.textTheme.erpBody.copyWith(color: t.textPrimary),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Pesquisar…',
        hintStyle: theme.textTheme.erpBody.copyWith(color: t.textMuted),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: DesignMetrics.iconSm,
          color: t.textMuted,
        ),
        prefixIconConstraints: BoxConstraints(
          minWidth: t.compactControlHeight,
          minHeight: t.compactControlHeight,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.sm),
        filled: true,
        fillColor: t.bgPrimary.withValues(alpha: 0.55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.radiusSm),
          borderSide: BorderSide(color: t.brandGreen.withValues(alpha: 0.45)),
        ),
      ),
    );
  }
}

class _NavGroup extends StatelessWidget {
  const _NavGroup({
    required this.title,
    required this.icon,
    required this.expanded,
    required this.groupActive,
    required this.onHeaderTap,
    required this.children,
  });

  final String title;
  final IconData icon;
  final bool expanded;
  final bool groupActive;
  final VoidCallback? onHeaderTap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NavHoverTile(
          onTap: onHeaderTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.sm),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: DesignMetrics.iconSm + 2,
                  color: groupActive ? t.brandGreen : t.textSecondary,
                ),
                SizedBox(width: s.sm),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.erpMenuItem.copyWith(
                          color: groupActive ? t.textPrimary : t.textSecondary,
                          fontWeight:
                              groupActive ? FontWeight.w600 : FontWeight.w500,
                        ),
                  ),
                ),
                if (onHeaderTap != null)
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    size: DesignMetrics.iconSm,
                    color: t.textMuted,
                  ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: Motion.durationFaster,
          curve: Motion.easeOut,
          alignment: Alignment.topCenter,
          child: expanded
              ? Padding(
                  padding: EdgeInsets.only(left: s.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Folha indentada — só texto (hierarquia clara, sem ícones).
class _NavLeafTile extends StatelessWidget {
  const _NavLeafTile({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Padding(
      padding: EdgeInsets.only(bottom: 1),
      child: _NavHoverTile(
        onTap: onTap,
        selected: active,
        child: Semantics(
          button: true,
          selected: active,
          label: label,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(t.radiusSm),
              color: active
                  ? t.brandGreen.withValues(alpha: 0.10)
                  : Colors.transparent,
            ),
            foregroundDecoration: active
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(t.radiusSm),
                    border: Border(
                      left: BorderSide(color: t.brandGreen, width: 2.5),
                    ),
                  )
                : null,
            padding: EdgeInsets.symmetric(
              horizontal: s.md,
              vertical: s.sm - 1,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.erpMenuItem.copyWith(
                    color: active ? t.textPrimary : t.textMuted,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hover / press partilhado (InkWell + radius do DS).
class _NavHoverTile extends StatelessWidget {
  const _NavHoverTile({
    required this.child,
    this.onTap,
    this.selected = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(t.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(t.radiusSm),
        hoverColor: t.textPrimary.withValues(alpha: 0.04),
        splashColor: t.brandGreen.withValues(alpha: 0.08),
        highlightColor: t.brandGreen.withValues(alpha: 0.05),
        onTap: onTap,
        child: child,
      ),
    );
  }
}
