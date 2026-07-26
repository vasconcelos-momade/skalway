import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../app/providers/app_theme_mode_provider.dart';
import '../../app/providers/auth_session_notifier.dart';
import '../../app/providers/session_access_notifier.dart';
import '../../app/router/routes.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/extensions.dart';
import '../../core/theme/dimensions.dart';
import '../responsive/pharma_screen_layout.dart';
import '../widgets/navigation/app_nav_config.dart';
import '../widgets/navigation/enterprise_sidebar.dart';
import '../widgets/navigation/sidebar_menu_icon.dart';
import '../widgets/sync/sync_status_strip.dart';
import 'tablet_layout.dart';

/// Shell enterprise: sidebar fixo no desktop (≥1280), drawer em tablet/mobile.
class DashboardLayout extends ConsumerStatefulWidget {
  const DashboardLayout({
    super.key,
    required this.child,
    this.navItemsOverride,
    this.navSectionsOverride,
    this.appTitle = 'Pharma ERP',
    this.showSyncStrip = true,
  });

  final Widget child;
  final List<AppNavItem>? navItemsOverride;
  final List<AppNavSection>? navSectionsOverride;
  final String appTitle;
  final bool showSyncStrip;

  @override
  ConsumerState<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends ConsumerState<DashboardLayout> {
  final GlobalKey<ScaffoldState> _shellKey = GlobalKey<ScaffoldState>();

  List<AppNavSection> _sectionsFor(SessionAccessState access) {
    if (widget.navSectionsOverride != null) {
      return widget.navSectionsOverride!;
    }
    if (widget.navItemsOverride != null) {
      return [
        AppNavSection(title: 'Menu', items: widget.navItemsOverride!),
      ];
    }
    return visibleNavSectionsForAccess(access);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final location = GoRouterState.of(context).uri.path;
    final access = ref.watch(sessionAccessProvider);
    final sections = _sectionsFor(access);
    final bp = ResponsiveBreakpoints.of(context);
    final isDesktop = bp.largerOrEqualTo(DESKTOP);
    final isTablet = bp.equals(TABLET);
    final isMobile = PharmaScreenLayout.isMobile(context);

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
      drawer: isDesktop
          ? null
          : _DrawerNav(
              location: location,
              sections: sections,
              onSelect: (path) {
                context.go(path);
                Navigator.of(context).pop();
              },
              onLogout: () => _logout(context),
            ),
      body: Row(
        children: [
          if (isDesktop)
            EnterpriseSidebar(
              location: location,
              sections: sections,
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

class _DrawerNav extends StatelessWidget {
  const _DrawerNav({
    required this.location,
    required this.sections,
    required this.onSelect,
    required this.onLogout,
  });

  final String location;
  final List<AppNavSection> sections;
  final ValueChanged<String> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Drawer(
      backgroundColor: t.bgSecondary,
      width: AppDimensions.sidebarExpanded + s.lg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EnterpriseNavBrand(
              trailing: IconButton(
                tooltip: 'Fechar',
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: t.textMuted),
              ),
            ),
            Expanded(
              child: EnterpriseNavMenu(
                location: location,
                sections: sections,
                onSelect: onSelect,
              ),
            ),
            EnterpriseNavLogout(onLogout: onLogout),
          ],
        ),
      ),
    );
  }
}
