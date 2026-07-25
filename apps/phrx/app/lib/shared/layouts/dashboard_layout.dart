import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../app/providers/app_theme_mode_provider.dart';
import '../../app/providers/auth_session_notifier.dart';
import '../../app/providers/session_access_notifier.dart';
import '../../app/router/routes.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/design_metrics.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/extensions.dart';
import '../../core/theme/pharma_surface.dart';
import '../../core/theme/dimensions.dart';
import '../responsive/pharma_screen_layout.dart';
import '../widgets/navigation/app_nav_config.dart';
import '../widgets/navigation/sidebar_menu_icon.dart';
import '../widgets/sync/sync_status_strip.dart';
import 'tablet_layout.dart';

/// Shell enterprise: sidebar animada, topbar, breadcrumbs, sync e adaptação tablet/mobile.
class DashboardLayout extends ConsumerStatefulWidget {
  const DashboardLayout({
    super.key,
    required this.child,
    this.navItemsOverride,
    this.appTitle = 'Pharma ERP',
    this.showSyncStrip = true,
  });

  final Widget child;
  final List<AppNavItem>? navItemsOverride;
  final String appTitle;
  final bool showSyncStrip;

  @override
  ConsumerState<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends ConsumerState<DashboardLayout> {
  bool _sidebarExpanded = true;
  final GlobalKey<ScaffoldState> _shellKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final location = GoRouterState.of(context).uri.path;
    final access = ref.watch(sessionAccessProvider);
    final navItems =
        widget.navItemsOverride ?? visibleNavItemsForAccess(access);
    final bp = ResponsiveBreakpoints.of(context);
    final isDesktop = bp.largerOrEqualTo(DESKTOP);
    final isTablet = bp.equals(TABLET);
    final isMobile = PharmaScreenLayout.isMobile(context);
    final sidebarExpanded = isDesktop && _sidebarExpanded;

    Widget body = Padding(
      padding: PharmaScreenLayout.pagePadding(context),
      child: widget.child,
    );

    if (isTablet && !isDesktop) {
      body = TabletLayout(child: body);
    }

    return Scaffold(
      key: _shellKey,
      backgroundColor: t.bgPrimary,
      drawer: _DrawerNav(
        location: location,
        navItems: navItems,
        onSelect: (path) {
          context.go(path);
          Navigator.of(context).pop();
        },
        onLogout: () => _logout(context),
      ),
      body: Row(
        children: [
          if (isDesktop)
            _Sidebar(
              location: location,
              navItems: navItems,
              expanded: sidebarExpanded,
              onToggle: () =>
                  setState(() => _sidebarExpanded = !_sidebarExpanded),
              onLogout: () => _logout(context),
            ),
          Expanded(
            child: Column(
              children: [
                _EnterpriseTopBar(
                  isDesktop: isDesktop,
                  isMobile: isMobile,
                  location: location,
                  onLogout: () => _logout(context),
                  onOpenDrawer: () => _shellKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: Container(color: t.bgPrimary, child: body),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? Theme(
              data: Theme.of(context).copyWith(
                navigationBarTheme: NavigationBarThemeData(
                  height: AppDimensions.topBarCompact,
                  indicatorColor: t.brandGreen.withValues(alpha: 0.2),
                ),
              ),
              child: NavigationBar(
                height: AppDimensions.topBarCompact,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                selectedIndex: _bottomNavIndex(location),
                onDestinationSelected: (i) {
                  if (i == 4) {
                    _shellKey.currentState?.openDrawer();
                    return;
                  }
                  switch (i) {
                    case 0:
                      context.go(AppRoutePaths.dashboard);
                      break;
                    case 1:
                      context.go(AppRoutePaths.pos);
                      break;
                    case 2:
                      context.go(AppRoutePaths.products);
                      break;
                    case 3:
                      context.go(AppRoutePaths.financeCashflow);
                      break;
                  }
                },
                destinations: [
                  NavigationDestination(
                    tooltip: 'Painel',
                    icon: Icon(
                      Icons.dashboard_outlined,
                      color: t.textSecondary,
                    ),
                    selectedIcon: Icon(Icons.dashboard, color: t.brandGreen),
                    label: '',
                  ),
                  NavigationDestination(
                    tooltip: 'PDV',
                    icon: Icon(
                      Icons.point_of_sale_outlined,
                      color: t.textSecondary,
                    ),
                    selectedIcon: Icon(
                      Icons.point_of_sale,
                      color: t.brandGreen,
                    ),
                    label: '',
                  ),
                  NavigationDestination(
                    tooltip: 'Produtos',
                    icon: Icon(
                      Icons.medication_outlined,
                      color: t.textSecondary,
                    ),
                    selectedIcon: Icon(Icons.medication, color: t.brandGreen),
                    label: '',
                  ),
                  NavigationDestination(
                    tooltip: 'Finanças',
                    icon: Icon(Icons.payments_outlined, color: t.textSecondary),
                    selectedIcon: Icon(Icons.payments, color: t.brandGreen),
                    label: '',
                  ),
                  NavigationDestination(
                    tooltip: 'Menu',
                    icon: SidebarMenuIcon(color: t.textSecondary),
                    selectedIcon: SidebarMenuIcon(color: t.brandGreen),
                    label: '',
                  ),
                ],
              ),
            )
          : null,
    );
  }

  int _bottomNavIndex(String path) {
    if (path == AppRoutePaths.dashboard || path.startsWith('/dashboard')) {
      return 0;
    }
    if (path == AppRoutePaths.pos || path.startsWith('/sales')) {
      return 1;
    }
    if (path == AppRoutePaths.products || path.startsWith('/pharmacy')) {
      return 2;
    }
    if (path == AppRoutePaths.financeCashflow ||
        path.startsWith('/app/finance')) {
      return 3;
    }
    if (path.startsWith('/stock')) {
      return 2;
    }
    return 4;
  }

  void _logout(BuildContext context) {
    ref.read(authSessionProvider.notifier).signOut().then((_) {
      if (context.mounted) context.go(AppRoutePaths.login);
    });
  }
}

class _EnterpriseTopBar extends ConsumerWidget {
  const _EnterpriseTopBar({
    required this.isDesktop,
    required this.isMobile,
    required this.location,
    required this.onLogout,
    required this.onOpenDrawer,
  });

  final bool isDesktop;
  final bool isMobile;
  final String location;
  final VoidCallback onLogout;
  final VoidCallback onOpenDrawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userName = ref.watch(
      authSessionProvider.select((auth) => auth.session?.user.name),
    );
    final section =
        navSectionTitleForPath(location) ?? AppRouteTitles.sectionFor(location);
    final compactSync = isMobile || MediaQuery.sizeOf(context).width < 520;
    final pagePadding = PharmaScreenLayout.pagePadding(context);
    final horizontalPadding = EdgeInsets.only(
      left: pagePadding.left,
      right: pagePadding.right,
    );
    final actionSpacing = compactSync ? s.sm : s.md;

    return Material(
      color: t.bgPrimary,
      animationDuration: kPharmaInstantThemeDuration,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Container(
        height: isDesktop
            ? AppDimensions.topBarDesktop
            : AppDimensions.topBarCompact,
        padding: horizontalPadding,
        child: Row(
          children: [
            if (!isDesktop && !isMobile) ...[
              IconButton(
                constraints: BoxConstraints(
                  minWidth: t.minTouchTarget,
                  minHeight: t.minTouchTarget,
                ),
                padding: EdgeInsets.zero,
                tooltip: 'Menu',
                icon: SidebarMenuIcon(color: t.textSecondary, size: t.iconMd),
                onPressed: onOpenDrawer,
              ),
              SizedBox(width: s.md),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'PhRx',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.erpOverline.copyWith(
                            color: t.brandGreen,
                          ),
                        ),
                        Text(
                          section,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.erpAppBarTitle.copyWith(
                            color: t.textPrimary,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Text(
                          'PhRx',
                          style: theme.textTheme.erpOverline.copyWith(
                            color: t.textMuted,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: s.sm),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: t.iconSm,
                            color: t.border,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            section,
                            style: theme.textTheme.erpOverline.copyWith(
                              color: t.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            SizedBox(width: isMobile ? s.sm : s.lg),
            Flexible(
              fit: FlexFit.loose,
              child: Align(
                alignment: Alignment.centerRight,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SyncStatusStrip(compact: compactSync),
                      SizedBox(width: actionSpacing),
                      IconButton(
                        constraints: BoxConstraints(
                          minWidth: t.minTouchTarget,
                          minHeight: t.minTouchTarget,
                        ),
                        padding: EdgeInsets.zero,
                        tooltip: isDark ? 'Tema claro' : 'Tema escuro',
                        onPressed: () {
                          ref.read(appThemeModeProvider.notifier).toggle();
                        },
                        icon: Icon(
                          isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          color: t.textSecondary,
                          size: t.iconMd,
                        ),
                      ),
                      SizedBox(width: actionSpacing),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: t.minTouchTarget,
                          minHeight: t.minTouchTarget,
                        ),
                        tooltip: 'Conta',
                        child: CircleAvatar(
                          radius: t.avatarMd / 2,
                          backgroundColor: t.brandGreen.withValues(alpha: 0.2),
                          child: Text(
                            _userInitials(userName),
                            style: theme.textTheme.erpOverline.copyWith(
                              color: t.brandGreen,
                            ),
                          ),
                        ),
                        onSelected: (v) {
                          if (v == 'logout') {
                            onLogout();
                          }
                          if (v == 'settings') {
                            context.go(AppRoutePaths.settings);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'profile',
                            child: Text('Perfil'),
                          ),
                          const PopupMenuItem(
                            value: 'settings',
                            child: Text('Configurações'),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'logout',
                            child: Text('Sair'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.location,
    required this.navItems,
    required this.expanded,
    required this.onToggle,
    required this.onLogout,
  });

  final String location;
  final List<AppNavItem> navItems;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final w = expanded
        ? AppDimensions.sidebarExpanded
        : AppDimensions.sidebarCollapsed;
    return ClipRect(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        width: w,
        child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.bgSecondary,
          border: Border(
            right: BorderSide(color: t.border.withValues(alpha: 0.65)),
          ),
          boxShadow: AppShadows.dialog(context),
        ),
        child: Column(
          children: [
            if (expanded)
              Container(
                height: 3,
                margin: EdgeInsets.fromLTRB(s.lg, s.sm, s.lg, 0),
                decoration: BoxDecoration(
                  color: t.brandGreen,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                expanded ? s.lg : s.sm,
                s.lg,
                expanded ? s.lg : s.sm,
                s.md,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedPadding(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: expanded ? s.md : s.sm,
                      vertical: expanded ? s.md : s.sm,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: t.card.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(t.radiusLg),
                        border: Border.all(
                          color: t.border.withValues(alpha: 0.55),
                        ),
                      ),
                      child: expanded
                          ? Row(
                              children: [
                                SizedBox(
                                  width: t.avatarMd + 4,
                                  height: t.avatarMd + 4,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(t.radiusMd),
                                    child: Image.asset(
                                      'assets/logos/logo_512.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                SizedBox(width: s.md),
                                Expanded(
                                  child: Text(
                                    'PharmaERP',
                                    style: Theme.of(context)
                                        .textTheme
                                        .erpAppName
                                        .copyWith(color: t.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          : SizedBox(
                                width: t.minTouchTarget,
                                height: t.minTouchTarget,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(t.radiusMd),
                                  child: Image.asset(
                                    'assets/logos/logo_512.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 4,
                    child: IconButton(
                      style: pharmaInstantButtonStyle(
                        IconButton.styleFrom(
                          backgroundColor: t.card,
                          side: BorderSide(color: t.border),
                          elevation: 2,
                          minimumSize: const Size.square(
                            DesignMetrics.iconButtonCompactSize,
                          ),
                          maximumSize: const Size.square(
                            DesignMetrics.iconButtonCompactSize,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      onPressed: onToggle,
                      icon: Icon(
                        expanded
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        size: DesignMetrics.iconSm,
                        color: t.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: t.border.withValues(alpha: 0.45)),
            Expanded(
              child: _NavList(
                location: location,
                navItems: navItems,
                expanded: expanded,
              ),
            ),
            Divider(height: 1, color: t.border.withValues(alpha: 0.45)),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: expanded ? s.lg : s.xs,
                vertical: s.sm,
              ),
              child: expanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: s.md,
                            vertical: s.sm,
                          ),
                          decoration: BoxDecoration(
                            color: t.card.withValues(alpha: 0.68),
                            borderRadius: BorderRadius.circular(t.radiusMd),
                            border: Border.all(
                              color: t.border.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: t.brandGreen,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              SizedBox(width: s.sm),
                              Expanded(
                                child: Text(
                                  'Sessão activa',
                                  style: Theme.of(context).textTheme.erpMenuItem
                                      .copyWith(color: t.textPrimary),
                                ),
                              ),
                              Text(
                                'ERP',
                                style: Theme.of(context).textTheme.erpOverline
                                    .copyWith(color: t.textMuted),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: s.sm),
                        OutlinedButton.icon(
                          onPressed: onLogout,
                          icon: Icon(
                            Icons.logout_rounded,
                            size: 18,
                            color: t.posDanger,
                          ),
                          label: Text(
                            'Encerrar sessão',
                            style: Theme.of(context)
                                .textTheme
                                .erpButtonSecondary
                                .copyWith(color: t.posDanger),
                          ),
                          style: pharmaInstantButtonStyle(
                            OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: t.posDanger.withValues(alpha: 0.35),
                              ),
                              backgroundColor: t.posDanger.withValues(
                                alpha: 0.06,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Tooltip(
                      message: 'Encerrar sessão',
                      child: OutlinedButton(
                        onPressed: onLogout,
                        style: pharmaInstantButtonStyle(
                          OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: t.posDanger.withValues(alpha: 0.35),
                            ),
                            backgroundColor: t.posDanger.withValues(
                              alpha: 0.06,
                            ),
                          ),
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: t.posDanger,
                        ),
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

class _NavList extends StatelessWidget {
  const _NavList({
    required this.location,
    required this.navItems,
    required this.expanded,
  });

  final String location;
  final List<AppNavItem> navItems;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    String? currentSection;
    final children = <Widget>[];

    for (final item in navItems) {
      if (item.isSectionLead) {
        currentSection = item.section;
        if (!expanded) {
          children.add(SizedBox(height: s.sm));
        } else {
          children.add(_ErpNavSectionHeader(title: item.section!));
        }
      }

      final active = location == item.path;
      final tooltipLabel = currentSection == null
          ? item.label
          : '$currentSection · ${item.label}';

      final tile = Padding(
        padding: EdgeInsets.only(left: s.sm, right: s.sm, top: 1, bottom: 1),
        child: Material(
          color: active
              ? t.brandGreen.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(t.radiusSm),
          child: InkWell(
            borderRadius: BorderRadius.circular(t.radiusSm),
            onTap: () => context.go(item.path),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(t.radiusSm),
                border: Border(
                  left: BorderSide(
                    color: active ? t.brandGreen : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: expanded ? s.md : s.sm,
                vertical: s.sm + 1,
              ),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: expanded ? 20 : 22,
                    color: active ? t.brandGreen : t.textSecondary,
                  ),
                  if (expanded) ...[
                    SizedBox(width: s.md),
                    Expanded(
                      child: Text(
                        item.label,
                        style:
                            (active
                                    ? Theme.of(
                                        context,
                                      ).textTheme.erpMenuItemActive
                                    : Theme.of(context).textTheme.erpMenuItem)
                                .copyWith(
                                  color: active
                                      ? t.textPrimary
                                      : t.textSecondary,
                                ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );

      children.add(
        expanded
            ? tile
            : Tooltip(
                message: tooltipLabel,
                waitDuration: const Duration(milliseconds: 400),
                child: tile,
              ),
      );
    }

    return Scrollbar(
      thumbVisibility: expanded,
      child: ListView(
        padding: EdgeInsets.fromLTRB(s.xs, s.sm, s.xs, s.lg),
        children: children,
      ),
    );
  }
}

class _ErpNavSectionHeader extends StatelessWidget {
  const _ErpNavSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    return Padding(
      padding: EdgeInsets.fromLTRB(s.sm, s.lg, s.sm, s.xs),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: s.md, vertical: s.sm),
        decoration: BoxDecoration(
          color: t.card.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(t.radiusSm),
          border: Border.all(color: t.border.withValues(alpha: 0.45)),
        ),
        child: Text(
          title.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.erpOverline.copyWith(color: t.textMuted),
        ),
      ),
    );
  }
}

class _DrawerNav extends StatelessWidget {
  const _DrawerNav({
    required this.location,
    required this.navItems,
    required this.onSelect,
    required this.onLogout,
  });

  final String location;
  final List<AppNavItem> navItems;
  final ValueChanged<String> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final drawerChildren = <Widget>[];

    for (final item in navItems) {
      if (item.isSectionLead) {
        drawerChildren.add(_ErpNavSectionHeader(title: item.section!));
      }

      final active = location == item.path;

      drawerChildren.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: s.sm),
          child: Material(
            color: active
                ? t.brandGreen.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(t.radiusSm),
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: EdgeInsets.symmetric(horizontal: s.md),
              leading: Icon(
                item.icon,
                size: 20,
                color: active ? t.brandGreen : t.textSecondary,
              ),
              title: Text(
                item.label,
                style: Theme.of(context).textTheme.erpTabLabel.copyWith(
                  color: active ? t.textPrimary : t.textSecondary,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              selected: active,
              onTap: () => onSelect(item.path),
            ),
          ),
        ),
      );
    }
    return Drawer(
      backgroundColor: t.bgSecondary,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(s.xl),
              child: Container(
                padding: EdgeInsets.all(s.md),
                decoration: BoxDecoration(
                  color: t.card.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(t.radiusLg),
                  border: Border.all(color: t.border.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: t.minTouchTarget,
                      height: t.minTouchTarget,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(t.radiusMd),
                        child: Image.asset(
                          'assets/logos/logo_512.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: s.md),
                    Expanded(
                      child: Text(
                        'PharmaERP',
                        style: Theme.of(context).textTheme.erpAppName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      style: pharmaInstantButtonStyle(
                        IconButton.styleFrom(
                          backgroundColor: t.bgPrimary,
                          side: BorderSide(
                            color: t.border.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: t.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: ListView(children: drawerChildren)),
            Padding(
              padding: EdgeInsets.fromLTRB(s.lg, s.sm, s.lg, s.lg),
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: Icon(Icons.logout_rounded, color: t.posDanger, size: 18),
                label: Text(
                  'Encerrar sessão',
                  style: Theme.of(
                    context,
                  ).textTheme.erpLabel.copyWith(color: t.posDanger),
                ),
                style: pharmaInstantButtonStyle(
                  OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    side: BorderSide(
                      color: t.posDanger.withValues(alpha: 0.28),
                    ),
                    backgroundColor: t.posDanger.withValues(alpha: 0.06),
                    padding: EdgeInsets.symmetric(
                      horizontal: s.md,
                      vertical: s.md,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
