import 'package:flutter/material.dart';

import '../../../../app/router/routes.dart';

class PlatformNavItem {
  const PlatformNavItem({
    this.section,
    required this.label,
    required this.path,
    required this.icon,
  });

  final String? section;
  final String label;
  final String path;
  final IconData icon;

  PlatformNavItem copyWith({String? section}) => PlatformNavItem(
        section: section ?? this.section,
        label: label,
        path: path,
        icon: icon,
      );
}

const List<PlatformNavItem> kPlatformNavItems = [
  PlatformNavItem(
    section: 'Plataforma',
    label: 'Dashboard',
    path: AppRoutePaths.platformDashboard,
    icon: Icons.dashboard_outlined,
  ),
  PlatformNavItem(
    label: 'Clientes',
    path: AppRoutePaths.platformTenants,
    icon: Icons.business_outlined,
  ),
  PlatformNavItem(
    label: 'Filiais',
    path: AppRoutePaths.platformBranches,
    icon: Icons.store_outlined,
  ),
  PlatformNavItem(
    label: 'Planos',
    path: AppRoutePaths.platformPlans,
    icon: Icons.layers_outlined,
  ),
  PlatformNavItem(
    label: 'Assinaturas',
    path: AppRoutePaths.platformSubscriptions,
    icon: Icons.card_membership_outlined,
  ),
  PlatformNavItem(
    label: 'Faturas',
    path: AppRoutePaths.platformInvoices,
    icon: Icons.receipt_long_outlined,
  ),
  PlatformNavItem(
    label: 'Pagamentos',
    path: AppRoutePaths.platformPayments,
    icon: Icons.payments_outlined,
  ),
  PlatformNavItem(
    label: 'Dispositivos',
    path: AppRoutePaths.platformDevices,
    icon: Icons.devices_outlined,
  ),
  PlatformNavItem(
    label: 'Sincronização',
    path: AppRoutePaths.platformSync,
    icon: Icons.sync_alt,
  ),
  PlatformNavItem(
    label: 'Auditoria',
    path: AppRoutePaths.platformAudit,
    icon: Icons.gavel_outlined,
  ),
  PlatformNavItem(
    label: 'Utilizadores',
    path: AppRoutePaths.platformUsers,
    icon: Icons.group_outlined,
  ),
  PlatformNavItem(
    label: 'Configurações',
    path: AppRoutePaths.platformSettings,
    icon: Icons.settings_outlined,
  ),
];

List<PlatformNavItem> platformNavItemsFlat() {
  final flat = <PlatformNavItem>[];
  for (var i = 0; i < kPlatformNavItems.length; i++) {
    final item = kPlatformNavItems[i];
    flat.add(item.copyWith(section: i == 0 ? item.section : null));
  }
  return flat;
}

String platformTitleForPath(String path) {
  for (final item in kPlatformNavItems) {
    if (item.path == path) return item.label;
  }
  if (path.startsWith('${AppRoutePaths.platformTenants}/')) {
    return 'Detalhe do Cliente';
  }
  return 'Plataforma';
}
