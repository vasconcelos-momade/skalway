import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/nav_groups_expanded_provider.dart';
import '../../../core/theme/design_metrics.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/dimensions.dart';
import '../../../core/theme/extensions.dart';
import 'app_nav_config.dart';

/// Sidebar desktop fixa (Notion / Linear / Slack / Fluent).
///
/// - Grupos com ícone + chevron (colapsáveis)
/// - Submenus mais indentados
/// - Activo: fundo discreto e indicador minimalista
/// - Sem poluição visual (sem caixas pesadas, sombras ou UPPERCASE)
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
      padding: EdgeInsets.fromLTRB(s.md, s.md, s.md, s.md),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(t.radiusSm),
            child: Image.asset(
              'assets/logos/logo_512.png',
              width: t.minTouchTarget,
              height: t.minTouchTarget,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: s.sm),
          Expanded(
            child: Text(
              'PhRx',
              style: Theme.of(context).textTheme.erpAppName.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
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

/// Logout discreto, integrado ao layout.
class EnterpriseNavLogout extends StatelessWidget {
  const EnterpriseNavLogout({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, color: t.border.withValues(alpha: 0.5)),
        Padding(
          padding: EdgeInsets.all(s.sm),
          child: SizedBox(
            height: t.compactControlHeight,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: t.posDanger,
                side: BorderSide(color: t.posDanger.withValues(alpha: 0.5)),
                padding: EdgeInsets.symmetric(horizontal: s.sm),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(t.radiusMd),
                ),
              ),
              onPressed: onLogout,
              child: Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: DesignMetrics.iconSm,
                  ),
                  SizedBox(width: s.sm),
                  Expanded(
                    child: Text(
                      'Encerrar sessão',
                      style: Theme.of(context).textTheme.erpMenuItem.copyWith(
                            color: t.posDanger,
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateActiveGroup();
  }

  @override
  void didUpdateWidget(EnterpriseNavMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _updateActiveGroup();
    }
  }

  void _updateActiveGroup() {
    if (widget.sections.isEmpty) return;
    
    final activeGroup = widget.sections.firstWhere(
      (group) => group.items.any((item) => item.path == widget.location),
      orElse: () => widget.sections.first,
    ).title;
    
    Future.microtask(() {
      if (mounted) {
        ref.read(navGroupsExpandedProvider.notifier).updateActiveGroup(activeGroup);
      }
    });
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
    final expandedGroups = ref.watch(navGroupsExpandedProvider);
    final sections = _filteredSections;
    final searching = _query.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showSearch)
          Padding(
            padding: EdgeInsets.fromLTRB(s.md, 0, s.md, s.md),
            child: _NavSearchField(controller: _searchController),
          ),
        Divider(height: 1, color: t.border.withValues(alpha: 0.3)),
        SizedBox(height: s.sm),
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
                    searching || expandedGroups.contains(group.title);
                final groupActive = group.items.any(
                  (item) => item.path == widget.location,
                );

                return Padding(
                  padding: EdgeInsets.only(bottom: s.md),
                  child: _NavGroup(
                    title: group.title,
                    icon: group.resolvedIcon,
                    expanded: isExpanded,
                    groupActive: groupActive,
                    onHeaderTap: searching
                        ? null
                        : () => ref
                            .read(navGroupsExpandedProvider.notifier)
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

    return SizedBox(
      height: t.compactControlHeight,
      child: TextField(
        controller: controller,
        style: theme.textTheme.erpBody.copyWith(color: t.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Pesquisar...',
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
          contentPadding: EdgeInsets.symmetric(horizontal: s.sm),
          filled: true,
          fillColor: t.bgPrimary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(t.radiusMd),
            borderSide: BorderSide(color: t.border.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(t.radiusMd),
            borderSide: BorderSide(color: t.border.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(t.radiusMd),
            borderSide: BorderSide(color: t.brandGreen.withValues(alpha: 0.5)),
          ),
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
    const double indicatorWidth = 4.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NavHoverTile(
          onTap: onHeaderTap,
          child: Container(
            height: t.compactControlHeight, // Mesma altura do input search
            decoration: BoxDecoration(
              color: groupActive ? t.brandGreen.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(t.radiusMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                    width: indicatorWidth,
                    decoration: BoxDecoration(
                      color: groupActive ? t.brandGreen : Colors.transparent,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(t.radiusMd),
                        bottomLeft: Radius.circular(t.radiusMd),
                      ),
                    ),
                  ),
                  SizedBox(width: s.sm),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: DesignMetrics.iconSm,
                          color: groupActive ? t.textPrimary : t.textSecondary,
                        ),
                        SizedBox(width: s.sm),
                        Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.erpMenuItem.copyWith(
                                    fontSize: 15,
                                    color: groupActive ? t.textPrimary : t.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          if (onHeaderTap != null)
                              Padding(
                                padding: EdgeInsets.only(right: s.sm),
                                child: AnimatedRotation(
                                turns: expanded ? 0.25 : 0.0,
                                duration: Motion.durationFaster,
                                curve: Motion.easeOut,
                                child: Icon(
                                  Icons.keyboard_arrow_right_rounded,
                                  size: 18,
                                  color: groupActive ? t.textPrimary : t.textMuted,
                                ),
                              ),
                             ),
                      ],
                    ),
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
                  padding: EdgeInsets.only(
                    left: indicatorWidth + s.sm + (DesignMetrics.iconSm / 2),
                    top: s.sm,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: t.border.withValues(alpha: 0.2),
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
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
      padding: EdgeInsets.only(bottom: s.xs),
      child: _NavHoverTile(
        onTap: onTap,
        selected: active,
        child: Semantics(
          button: true,
          selected: active,
          label: label,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(t.radiusSm),
                bottomRight: Radius.circular(t.radiusSm),
              ),
              color: active
                  ? t.brandGreen.withValues(alpha: 0.08)
                  : Colors.transparent,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: s.sm,
              vertical: s.sm,
            ),
            child: Row(
              children: [
                Transform.translate(
                  offset: const Offset(-7, 0), // Puxa o ícone para alinhar sobre a linha esquerda
                  child: Icon(
                    Icons.radio_button_unchecked,
                    size: 14,
                    color: active ? t.brandGreen : t.textMuted.withValues(alpha: 0.5),
                  ),
                ),
                SizedBox(width: s.xs),
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(-7, 0), // Ajusta o texto para manter o espaçamento correcto
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.erpMenuItem.copyWith(
                            color: active ? t.textPrimary : t.textMuted,
                            fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                          ),
                    ),
                  ),
                ),
              ],
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
        splashColor: t.textPrimary.withValues(alpha: 0.08),
        highlightColor: t.textPrimary.withValues(alpha: 0.05),
        onTap: onTap,
        child: child,
      ),
    );
  }
}
