import 'package:flutter/material.dart';

import '../../../../app/router/routes.dart';
import '../../../../shared/widgets/navigation/app_nav_config.dart';

/// Títulos das secções do Painel Admin (SaaS).
abstract final class PlatformNavSections {
  PlatformNavSections._();

  static const dashboard = 'Dashboard';
  static const subscricao = 'Subscrição';
  static const comercial = 'Comercial';
  static const seguranca = 'Segurança';
  static const configuracoes = 'Configurações';
}

/// Menu agrupado do Painel Admin — fonte única para Sidebar, Drawer e Bottom Nav.
const List<AppNavSection> kPlatformNavSections = <AppNavSection>[
  AppNavSection(
    title: PlatformNavSections.dashboard,
    icon: Icons.space_dashboard_rounded,
    items: <AppNavItem>[
      AppNavItem(
        label: 'Dashboard',
        path: AppRoutePaths.platformDashboard,
        icon: Icons.space_dashboard_rounded,
      ),
    ],
  ),
  AppNavSection(
    title: PlatformNavSections.subscricao,
    icon: Icons.apartment_rounded,
    items: <AppNavItem>[
      AppNavItem(
        label: 'Tenantes',
        path: AppRoutePaths.platformSubscriptions,
        icon: Icons.business_rounded,
      ),
      AppNavItem(
        label: 'Branches / Filiais',
        path: AppRoutePaths.platformBranches,
        icon: Icons.storefront_rounded,
      ),
    ],
  ),
  AppNavSection(
    title: PlatformNavSections.comercial,
    icon: Icons.storefront_rounded,
    items: <AppNavItem>[
      AppNavItem(
        label: 'Faturas',
        path: AppRoutePaths.platformInvoices,
        icon: Icons.receipt_long_rounded,
      ),
      AppNavItem(
        label: 'Pagamentos',
        path: AppRoutePaths.platformPayments,
        icon: Icons.payments_rounded,
      ),
    ],
  ),
  AppNavSection(
    title: PlatformNavSections.seguranca,
    icon: Icons.shield_rounded,
    items: <AppNavItem>[
      AppNavItem(
        label: 'Utilizadores',
        path: AppRoutePaths.platformUsers,
        icon: Icons.group_rounded,
      ),
      AppNavItem(
        label: 'Auditoria',
        path: AppRoutePaths.platformAudit,
        icon: Icons.gavel_rounded,
      ),
    ],
  ),
  AppNavSection(
    title: PlatformNavSections.configuracoes,
    icon: Icons.settings_rounded,
    items: <AppNavItem>[
      AppNavItem(
        label: 'Planos',
        path: AppRoutePaths.platformPlans,
        icon: Icons.layers_rounded,
      ),
      AppNavItem(
        label: 'Empresa',
        path: AppRoutePaths.platformCompany,
        icon: Icons.business_center_rounded,
      ),
    ],
  ),
];

/// Destinos principais do Bottom Navigation (mobile) do Painel Admin.
const List<AppNavItem> kPlatformBottomNavPrimary = <AppNavItem>[
  AppNavItem(
    label: 'Dashboard',
    path: AppRoutePaths.platformDashboard,
    icon: Icons.space_dashboard_rounded,
  ),
  AppNavItem(
    label: 'Tenantes',
    path: AppRoutePaths.platformSubscriptions,
    icon: Icons.business_rounded,
  ),
  AppNavItem(
    label: 'Faturas',
    path: AppRoutePaths.platformInvoices,
    icon: Icons.receipt_long_rounded,
  ),
  AppNavItem(
    label: 'Utilizadores',
    path: AppRoutePaths.platformUsers,
    icon: Icons.group_rounded,
  ),
];

/// Itens do Bottom Sheet "Mais" (mobile).
List<AppNavItem> platformMoreNavItems() {
  const primaryPaths = {
    AppRoutePaths.platformDashboard,
    AppRoutePaths.platformSubscriptions,
    AppRoutePaths.platformInvoices,
    AppRoutePaths.platformUsers,
  };
  return [
    for (final section in kPlatformNavSections)
      for (final item in section.items)
        if (!primaryPaths.contains(item.path)) item,
  ];
}

bool platformNavPathMatches(String location, String itemPath) {
  if (location == itemPath) return true;
  if ((itemPath == AppRoutePaths.platformTenants ||
          itemPath == AppRoutePaths.platformSubscriptions) &&
      location.startsWith('${AppRoutePaths.platformTenants}/')) {
    return true;
  }
  if (itemPath == AppRoutePaths.platformSubscriptions &&
      location == AppRoutePaths.platformTenants) {
    return true;
  }
  return false;
}

String platformTitleForPath(String path) {
  for (final section in kPlatformNavSections) {
    for (final item in section.items) {
      if (platformNavPathMatches(path, item.path)) return item.label;
    }
  }
  if (path.startsWith('${AppRoutePaths.platformTenants}/')) {
    return 'Subscrição do tenant';
  }
  return 'Plataforma';
}

String? platformSectionTitleForPath(String path) {
  for (final section in kPlatformNavSections) {
    for (final item in section.items) {
      if (platformNavPathMatches(path, item.path)) return section.title;
    }
  }
  return null;
}
