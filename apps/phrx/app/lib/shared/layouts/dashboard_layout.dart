import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../app/providers/app_theme_mode_provider.dart';
import '../../app/providers/auth_session_notifier.dart';
import '../../app/providers/session_access_notifier.dart';
import '../../app/router/routes.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/dimensions.dart';
import '../../core/theme/extensions.dart';
import '../../core/theme/pharma_surface.dart';
import '../responsive/pharma_screen_layout.dart';
import '../widgets/menus/enterprise_dropdown_menu.dart';
import '../widgets/navigation/app_nav_config.dart';
import '../widgets/navigation/enterprise_sidebar.dart';
import '../widgets/navigation/sidebar_menu_icon.dart';
import '../refresh/page_refresh.dart';
import 'tablet_layout.dart';

/// Shell enterprise: sidebar fixo no desktop (≥1280), drawer em tablet/mobile.
class DashboardLayout extends ConsumerStatefulWidget {
  const DashboardLayout({
    super.key,
    required this.child,
    this.navItemsOverride,
    this.navSectionsOverride,
    this.appTitle = 'Pharma ERP',
  });

  final Widget child;
  final List<AppNavItem>? navItemsOverride;
  final List<AppNavSection>? navSectionsOverride;
  final String appTitle;

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
                  indicatorColor: context.colors.primary.withValues(
                    alpha: Theme.of(context).brightness == Brightness.light ? 0.25 : 0.15,
                  ),
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
                    selectedIcon: Icon(Icons.dashboard, color: t.textPrimary),
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
                      color: t.textPrimary,
                    ),
                    label: '',
                  ),
                  NavigationDestination(
                    tooltip: 'Produtos',
                    icon: Icon(
                      Icons.medication_outlined,
                      color: t.textSecondary,
                    ),
                    selectedIcon: Icon(Icons.medication, color: t.textPrimary),
                    label: '',
                  ),
                  NavigationDestination(
                    tooltip: 'Finanças',
                    icon: Icon(Icons.payments_outlined, color: t.textSecondary),
                    selectedIcon: Icon(Icons.payments, color: t.textPrimary),
                    label: '',
                  ),
                  NavigationDestination(
                    tooltip: 'Menu',
                    icon: SidebarMenuIcon(color: t.textSecondary),
                    selectedIcon: SidebarMenuIcon(color: t.textPrimary),
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
    required this.onOpenDrawer,
  });

  final bool isDesktop;
  final bool isMobile;
  final String location;
  final VoidCallback onOpenDrawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final theme = Theme.of(context);
    final themeMode = ref.watch(appThemeModeProvider);
    final section =
        navSectionTitleForPath(location) ?? AppRouteTitles.sectionFor(location);
    final compactActions = isMobile || MediaQuery.sizeOf(context).width < 520;
    final pagePadding = PharmaScreenLayout.pagePadding(context);
    final horizontalPadding = EdgeInsets.only(
      left: pagePadding.left,
      right: pagePadding.right,
    );
    final actionSpacing = compactActions ? s.sm : s.md;

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
                            color: t.textSecondary,
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
                      const _PageRefreshAction(),
                      SizedBox(width: actionSpacing),
                      _ThemeModeMenuButton(themeMode: themeMode),
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

class _ThemeModeMenuButton extends ConsumerWidget {
  const _ThemeModeMenuButton({required this.themeMode});

  final ThemeMode themeMode;

  IconData get _icon => switch (themeMode) {
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
        ThemeMode.system => Icons.brightness_auto_outlined,
      };

  String get _tooltip => switch (themeMode) {
        ThemeMode.light => 'Tema claro',
        ThemeMode.dark => 'Tema escuro',
        ThemeMode.system => 'Tema do sistema',
      };

  Future<void> _openMenu(BuildContext context, WidgetRef ref) async {
    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;

    final offset = box.localToGlobal(Offset.zero, ancestor: overlay);
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(offset.dx, offset.dy, box.size.width, box.size.height),
      Offset.zero & overlay.size,
    );

    final selected = await showEnterpriseDropdownMenu<ThemeMode>(
      context: context,
      position: position,
      items: [
        EnterpriseDropdownItem(
          value: ThemeMode.light,
          label: 'Tema claro',
          icon: Icons.light_mode_outlined,
          selected: themeMode == ThemeMode.light,
        ),
        EnterpriseDropdownItem(
          value: ThemeMode.dark,
          label: 'Tema escuro',
          icon: Icons.dark_mode_outlined,
          selected: themeMode == ThemeMode.dark,
        ),
        EnterpriseDropdownItem(
          value: ThemeMode.system,
          label: 'Tema do sistema',
          icon: Icons.brightness_auto_outlined,
          selected: themeMode == ThemeMode.system,
        ),
      ],
    );

    if (selected != null) {
      ref.read(appThemeModeProvider.notifier).setMode(selected);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;

    return IconButton(
      constraints: BoxConstraints(
        minWidth: t.minTouchTarget,
        minHeight: t.minTouchTarget,
      ),
      padding: EdgeInsets.zero,
      tooltip: _tooltip,
      onPressed: () => _openMenu(context, ref),
      icon: Icon(_icon, color: t.textSecondary, size: t.iconMd),
    );
  }
}

class _PageRefreshAction extends ConsumerWidget {
  const _PageRefreshAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.pharmaTokens;
    final refresh = ref.watch(pageRefreshProvider);
    final canRefresh = refresh.canRefresh;
    final isRefreshing = refresh.isRefreshing;

    return IconButton(
      constraints: BoxConstraints(
        minWidth: t.minTouchTarget,
        minHeight: t.minTouchTarget,
      ),
      padding: EdgeInsets.zero,
      tooltip: 'Atualizar',
      onPressed: canRefresh
          ? () => ref.read(pageRefreshProvider.notifier).refresh()
          : null,
      icon: isRefreshing
          ? SizedBox(
              width: t.iconMd,
              height: t.iconMd,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: t.textSecondary,
              ),
            )
          : Icon(
              Icons.refresh_rounded,
              color: canRefresh || isRefreshing
                  ? t.textSecondary
                  : t.textMuted.withValues(alpha: 0.45),
              size: t.iconMd,
            ),
    );
  }
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
