import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/auth_session_notifier.dart';
import '../../../app/providers/nav_groups_expanded_provider.dart';
import '../../../app/router/routes.dart';
import '../../../core/theme/app_shadows.dart';
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
/// - Elevação mínima + borda vertical face ao body
class EnterpriseSidebar extends StatelessWidget {
  const EnterpriseSidebar({
    super.key,
    required this.location,
    required this.sections,
    required this.onLogout,
    this.brandTitle,
    this.brandSubtitle,
    this.searchHint,
  });

  final String location;
  final List<AppNavSection> sections;
  final VoidCallback onLogout;
  final String? brandTitle;
  final String? brandSubtitle;
  final String? searchHint;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;

    return SizedBox(
      width: AppDimensions.sidebarExpanded,
      child: Material(
        color: t.surface1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.surface1,
            border: Border(
              right: BorderSide(
                color: t.border,
                width: BorderTokens.width,
              ),
            ),
            boxShadow: AppShadows.panelEdge(context, fromLeft: true),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EnterpriseNavBrand(
                title: brandTitle,
                subtitle: brandSubtitle,
              ),
              Expanded(
                child: EnterpriseNavMenu(
                  location: location,
                  sections: sections,
                  searchHint: searchHint,
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

/// Marca minimalista (logo + nome + subtítulo opcional).
class EnterpriseNavBrand extends StatelessWidget {
  const EnterpriseNavBrand({
    super.key,
    this.trailing,
    this.title,
    this.subtitle,
  });

  final Widget? trailing;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final brand = title ?? 'PhRx';

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  brand,
                  style: Theme.of(context).textTheme.erpAppName.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.erpCaption.copyWith(
                          color: t.textSecondary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Logout discreto, integrado ao layout.
class EnterpriseNavLogout extends ConsumerWidget {
  const EnterpriseNavLogout({super.key, required this.onLogout});

  final VoidCallback onLogout;

  String _userInitials(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return '?';
    final parts = trimmed
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final theme = Theme.of(context);
    final auth = ref.watch(authSessionProvider);
    final user = auth.session?.user;
    final inTenantBranch = auth.hasTenantContext;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, color: t.border),
        Padding(
          padding: EdgeInsets.all(s.sm),
          child: MenuAnchor(
            alignmentOffset: Offset(0, -SpacingTokens.sm),
            style: MenuStyle(
              backgroundColor: WidgetStatePropertyAll(t.surface4),
              elevation: const WidgetStatePropertyAll(0),
              shadowColor: const WidgetStatePropertyAll(Colors.transparent),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(t.radiusXl),
                  side: BorderSide(color: t.borderSubtle),
                ),
              ),
            ),
            menuChildren: [
              MenuItemButton(
                onPressed: () {},
                leadingIcon: Icon(
                  Icons.person_rounded,
                  color: t.textSecondary,
                  size: DesignMetrics.iconSm,
                ),
                child: Text(
                  'Perfil',
                  style: theme.textTheme.erpMenuItem.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              MenuItemButton(
                onPressed: () {},
                leadingIcon: Icon(
                  Icons.tune_rounded,
                  color: t.textSecondary,
                  size: DesignMetrics.iconSm,
                ),
                child: Text(
                  'Preferências',
                  style: theme.textTheme.erpMenuItem.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (inTenantBranch)
                MenuItemButton(
                  onPressed: () async {
                    await ref
                        .read(authSessionProvider.notifier)
                        .clearTenantContext();
                    if (!context.mounted) return;
                    final isSuperAdmin =
                        ref.read(authSessionProvider).isSuperAdmin;
                    context.go(
                      isSuperAdmin
                          ? AppRoutePaths.authAccessSelection
                          : AppRoutePaths.authBranchSelection,
                    );
                  },
                  leadingIcon: Icon(
                    Icons.swap_horiz_rounded,
                    color: t.textSecondary,
                    size: DesignMetrics.iconSm,
                  ),
                  child: Text(
                    'Trocar Branch/Filial',
                    style: theme.textTheme.erpMenuItem.copyWith(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (inTenantBranch &&
                  (ref.watch(authSessionProvider).isSuperAdmin))
                MenuItemButton(
                  onPressed: () async {
                    await ref
                        .read(authSessionProvider.notifier)
                        .clearTenantContext();
                    if (!context.mounted) return;
                    context.go(AppRoutePaths.platformDashboard);
                  },
                  leadingIcon: Icon(
                    Icons.admin_panel_settings_outlined,
                    color: t.textSecondary,
                    size: DesignMetrics.iconSm,
                  ),
                  child: Text(
                    'PhRx Plataforma',
                    style: theme.textTheme.erpMenuItem.copyWith(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const Divider(height: 1),
              MenuItemButton(
                onPressed: onLogout,
                leadingIcon: Icon(
                  Icons.logout_rounded,
                  color: t.posDanger,
                  size: DesignMetrics.iconSm,
                ),
                child: Text(
                  'Sair',
                  style: theme.textTheme.erpMenuItem.copyWith(
                    color: t.posDanger,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            builder: (context, controller, child) {
              return _NavHoverTile(
                onTap: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: s.sm,
                    vertical: s.sm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: t.avatarMd,
                        height: t.avatarMd,
                        decoration: BoxDecoration(
                          color: t.brandGreen,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _userInitials(user?.name),
                          style: theme.textTheme.erpCaption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: s.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user?.name ?? 'Utilizador',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.erpMenuItem.copyWith(
                                color: t.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              user?.email ?? 'Sem e-mail',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.erpCaption.copyWith(
                                color: t.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.expand_more_rounded,
                        size: DesignMetrics.iconSm,
                        color: t.textMuted,
                      ),
                    ],
                  ),
                ),
              );
            },
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
    this.searchHint,
  });

  final String location;
  final List<AppNavSection> sections;
  final ValueChanged<String> onSelect;
  final bool showSearch;
  final String? searchHint;

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

    final activeGroup = widget.sections
        .firstWhere(
          (group) => group.items.any(
            (item) => _pathMatches(widget.location, item.path),
          ),
          orElse: () => widget.sections.first,
        )
        .title;

    Future.microtask(() {
      if (mounted) {
        ref.read(navGroupsExpandedProvider.notifier).updateActiveGroup(activeGroup);
      }
    });
  }

  bool _pathMatches(String location, String itemPath) {
    if (location == itemPath) return true;
    if (itemPath != '/' && location.startsWith('$itemPath/')) return true;
    return false;
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
            child: _NavSearchField(
              controller: _searchController,
              hintText: widget.searchHint ?? 'Pesquisar...',
            ),
          ),
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
                final isSingle = group.items.length == 1;
                final single = isSingle ? group.items.first : null;
                final groupActive = group.items.any(
                  (item) => _pathMatches(widget.location, item.path),
                );

                // Secção com um único destino: tile directo (ex.: Dashboard).
                if (isSingle && single != null) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: s.md),
                    child: _NavPrimaryTile(
                      label: group.title,
                      icon: group.resolvedIcon,
                      active: groupActive,
                      onTap: () => widget.onSelect(single.path),
                    ),
                  );
                }

                final isExpanded =
                    searching || expandedGroups.contains(group.title);

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
                          active: _pathMatches(widget.location, item.path),
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
  const _NavSearchField({
    required this.controller,
    this.hintText = 'Pesquisar...',
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final colors = context.colors;
    final s = context.spacing;
    final theme = Theme.of(context);

    return SizedBox(
      height: t.compactControlHeight,
      child: TextField(
        controller: controller,
        style: theme.textTheme.erpBody.copyWith(color: t.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
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
          filled: false,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(t.radiusMd),
            borderSide: BorderSide(color: t.borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(t.radiusMd),
            borderSide: BorderSide(color: t.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(t.radiusMd),
            borderSide: BorderSide(color: colors.primary),
          ),
        ),
      ),
    );
  }
}

class _NavPrimaryTile extends StatelessWidget {
  const _NavPrimaryTile({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final colors = context.colors;
    final s = context.spacing;
    final primary = colors.primary;

    return _NavHoverTile(
      onTap: onTap,
      selected: active,
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: Container(
          height: t.compactControlHeight,
          decoration: BoxDecoration(
            color: active ? primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(t.radiusMd),
          ),
          padding: EdgeInsets.symmetric(horizontal: s.sm),
          child: Row(
            children: [
              Icon(
                icon,
                size: DesignMetrics.iconSm,
                color: active ? primary : t.textSecondary,
              ),
              SizedBox(width: s.sm),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.erpMenuItem.copyWith(
                        color: active ? primary : t.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
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
    final colors = context.colors;
    final s = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NavHoverTile(
          onTap: onHeaderTap,
          child: Container(
            height: t.compactControlHeight, // Mesma altura do input search
            decoration: BoxDecoration(
              color: groupActive ? colors.sidebarActiveBackground : Colors.transparent,
              borderRadius: BorderRadius.circular(t.radiusMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                    width: BorderTokens.indicator,
                    decoration: BoxDecoration(
                      color: groupActive
                          ? colors.sidebarActiveIndicator
                          : Colors.transparent,
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
                                duration: MotionTokens.durationFast,
                                curve: MotionTokens.ease,
                                child: Icon(
                                  Icons.keyboard_arrow_right_rounded,
                                  size: DesignMetrics.iconSm,
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
          duration: MotionTokens.durationFast,
          curve: MotionTokens.ease,
          alignment: Alignment.topCenter,
          child: expanded
              ? Padding(
                  padding: EdgeInsets.only(
                    left: SpacingTokens.xs + s.sm + (DesignMetrics.iconSm / 2),
                    top: s.sm,
                  ),
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
    final colors = context.colors;
    final s = context.spacing;
    final primary = colors.primary;

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
              borderRadius: BorderRadius.circular(t.radiusMd),
              color: active ? primary.withValues(alpha: 0.12) : Colors.transparent,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: s.sm,
              vertical: s.sm,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.erpMenuItem.copyWith(
                    color: active ? primary : t.textSecondary,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
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
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(t.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(t.radiusSm),
        hoverColor: colors.neutralSubtle,
        splashColor: colors.fieldHover,
        highlightColor: colors.neutralSubtle,
        onTap: onTap,
        child: child,
      ),
    );
  }
}
