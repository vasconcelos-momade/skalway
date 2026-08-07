import 'package:flutter/material.dart';

import '../../../app/providers/session_access_notifier.dart';
import '../../../app/router/routes.dart';
import '../../../modules/admin/users/domain/entities/user_entities.dart';

/// Títulos oficiais das secções — única fonte para sidebar, drawer e tags de página.
abstract final class AppNavSections {
  AppNavSections._();

  static const dashboard = 'Dashboard';
  static const terminal = 'Terminal';
  static const pharmacy = 'Farmácia';
  static const finance = 'Financeiro';
  static const regulatory = 'Regulatório';
  static const audit = 'Auditoria';
  static const administration = 'Administração';
  static const system = 'Sistema';
}

/// Entrada de navegação (item folha).
class AppNavItem {
  const AppNavItem({
    this.section,
    required this.label,
    required this.path,
    required this.icon,
    this.permissionModule,
    this.permissionAction = 'VIEW',
  });

  final String? section;
  final String label;
  final String path;
  final IconData icon;
  final String? permissionModule;
  final String permissionAction;

  bool get isSectionLead => section != null;

  AppNavItem copyWith({
    String? section,
    String? label,
    String? path,
    IconData? icon,
    String? permissionModule,
    String? permissionAction,
  }) {
    return AppNavItem(
      section: section ?? this.section,
      label: label ?? this.label,
      path: path ?? this.path,
      icon: icon ?? this.icon,
      permissionModule: permissionModule ?? this.permissionModule,
      permissionAction: permissionAction ?? this.permissionAction,
    );
  }
}

class AppNavSection {
  const AppNavSection({
    required this.title,
    required this.items,
    this.icon,
  });

  final String title;
  final List<AppNavItem> items;
  final IconData? icon;

  IconData get resolvedIcon => icon ?? navSectionIconForTitle(title);
}

/// Ícone do grupo (Notion/Linear: só o grupo tem ícone forte).
IconData navSectionIconForTitle(String title) {
  return switch (title) {
    AppNavSections.dashboard => Icons.space_dashboard_outlined,
    AppNavSections.terminal => Icons.point_of_sale_outlined,
    AppNavSections.pharmacy => Icons.local_pharmacy_outlined,
    AppNavSections.finance => Icons.account_balance_wallet_outlined,
    AppNavSections.regulatory => Icons.verified_user_outlined,
    AppNavSections.audit => Icons.history_edu_outlined,
    AppNavSections.administration => Icons.admin_panel_settings_outlined,
    AppNavSections.system => Icons.settings_outlined,
    'Dashboard' => Icons.space_dashboard_rounded,
    'Clientes' => Icons.apartment_rounded,
    'Comercial' => Icons.storefront_rounded,
    'Infraestrutura' => Icons.dns_rounded,
    'Segurança' => Icons.shield_rounded,
    'Configurações' => Icons.settings_rounded,
    _ => Icons.folder_outlined,
  };
}

/// Menu ERP — Dashboard com páginas dedicadas (sem hub de tabs).
const List<AppNavSection> kAppNavSections = <AppNavSection>[
  AppNavSection(
    title: AppNavSections.dashboard,
    items: <AppNavItem>[
      AppNavItem(
        label: 'Executivo',
        path: AppRoutePaths.dashboard,
        icon: Icons.dashboard_outlined,
        permissionModule: 'RELATORIOS',
      ),
      AppNavItem(
        label: 'Farmácia',
        path: AppRoutePaths.dashboardPharmacy,
        icon: Icons.local_pharmacy_outlined,
        permissionModule: 'DASHBOARD_FARMACIA',
      ),
      AppNavItem(
        label: 'Financeiro',
        path: AppRoutePaths.dashboardFinance,
        icon: Icons.account_balance_outlined,
        permissionModule: 'RELATORIOS',
      ),
      AppNavItem(
        label: 'Caixa',
        path: AppRoutePaths.dashboardCashier,
        icon: Icons.point_of_sale_outlined,
        permissionModule: 'DASHBOARD_CAIXA',
      ),
    ],
  ),
  AppNavSection(
    title: AppNavSections.terminal,
    items: <AppNavItem>[
      AppNavItem(
        label: 'POS / Caixa',
        path: AppRoutePaths.pos,
        icon: Icons.point_of_sale_outlined,
        permissionModule: 'POS',
      ),
      AppNavItem(
        label: 'Operacional PDV',
        path: AppRoutePaths.salesInvoices,
        icon: Icons.receipt_long_outlined,
        permissionModule: 'POS',
      ),
      AppNavItem(
        label: 'Faturas Proforma',
        path: AppRoutePaths.salesProformaInvoices,
        icon: Icons.request_quote_outlined,
        permissionModule: 'PROFORMA_INVOICES',
      ),
      AppNavItem(
        label: 'Clientes',
        path: AppRoutePaths.salesCustomers,
        icon: Icons.people_outline,
        permissionModule: 'CLIENTES',
      ),
    ],
  ),
  AppNavSection(
    title: AppNavSections.pharmacy,
    items: <AppNavItem>[
      AppNavItem(
        label: 'Produtos',
        path: AppRoutePaths.products,
        icon: Icons.medication_outlined,
        permissionModule: 'PRODUTOS',
      ),
      AppNavItem(
        label: 'Categorias',
        path: AppRoutePaths.pharmacyCategories,
        icon: Icons.category_outlined,
        permissionModule: 'PRODUTOS',
      ),
      AppNavItem(
        label: 'Estoque & Lotes',
        path: AppRoutePaths.pharmacyStock,
        icon: Icons.layers_outlined,
        permissionModule: 'LOTES',
      ),
      AppNavItem(
        label: 'Inventário',
        path: AppRoutePaths.stockInventory,
        icon: Icons.fact_check_outlined,
        permissionModule: 'INVENTARIO',
      ),
      AppNavItem(
        label: 'Sugestão de Compras',
        path: AppRoutePaths.stockPurchaseSuggestions,
        icon: Icons.auto_awesome_outlined,
        permissionModule: 'COMPRAS',
      ),
      AppNavItem(
        label: 'Movimentações',
        path: AppRoutePaths.stockMovements,
        icon: Icons.swap_horiz,
        permissionModule: 'INVENTARIO',
      ),
      AppNavItem(
        label: 'Fornecedores',
        path: AppRoutePaths.stockSuppliers,
        icon: Icons.local_shipping_outlined,
        permissionModule: 'FORNECEDORES',
      ),
    ],
  ),
  AppNavSection(
    title: AppNavSections.finance,
    items: <AppNavItem>[
      AppNavItem(
        label: 'Fluxo de Caixa',
        path: AppRoutePaths.financeCashflow,
        icon: Icons.stacked_line_chart,
        permissionModule: 'CAIXA',
      ),
      AppNavItem(
        label: 'Receita/Faturamento',
        path: AppRoutePaths.financeRevenue,
        icon: Icons.trending_up,
        permissionModule: 'CAIXA',
      ),
    ],
  ),
  AppNavSection(
    title: AppNavSections.regulatory,
    items: <AppNavItem>[
      AppNavItem(
        label: 'Mapa de Receitas',
        path: AppRoutePaths.recipesBook,
        icon: Icons.menu_book_outlined,
        permissionModule: 'RELATORIOS',
      ),
      AppNavItem(
        label: 'Mapa de Psicotrópicos',
        path: AppRoutePaths.psychotropics,
        icon: Icons.medication_outlined,
        permissionModule: 'RELATORIOS',
      ),
      AppNavItem(
        label: 'Sanitário',
        path: AppRoutePaths.regulatory,
        icon: Icons.health_and_safety_outlined,
        permissionModule: 'RELATORIOS',
      ),
    ],
  ),
  AppNavSection(
    title: AppNavSections.audit,
    items: <AppNavItem>[
      AppNavItem(
        label: 'Logs',
        path: AppRoutePaths.auditLogs,
        icon: Icons.history_outlined,
        permissionModule: 'RELATORIOS',
      ),
    ],
  ),
  AppNavSection(
    title: AppNavSections.administration,
    items: <AppNavItem>[
      AppNavItem(
        label: 'Utilizadores',
        path: AppRoutePaths.users,
        icon: Icons.group_outlined,
        permissionModule: 'UTILIZADORES',
      ),
    ],
  ),
  AppNavSection(
    title: AppNavSections.system,
    items: <AppNavItem>[
      AppNavItem(
        label: 'Filial',
        path: AppRoutePaths.settingsBranch,
        icon: Icons.storefront_outlined,
        permissionModule: 'CONFIGURACOES',
      ),
      AppNavItem(
        label: 'Terminais',
        path: AppRoutePaths.settingsTerminals,
        icon: Icons.computer_outlined,
        permissionModule: 'CONFIGURACOES',
      ),
      AppNavItem(
        label: 'Impressoras',
        path: AppRoutePaths.settingsPrinters,
        icon: Icons.print_outlined,
        permissionModule: 'CONFIGURACOES',
      ),
    ],
  ),
];

bool _canAccessNavItem(AppNavItem item, SessionAccessState access) {
  final module = item.permissionModule;
  if (module == null) {
    return true;
  }
  if (!access.isResolved || access.viewState == SessionAccessViewState.error) {
    return true;
  }
  return access.can(module, item.permissionAction);
}

List<AppNavItem> buildFlatNavItems(List<AppNavSection> sections) {
  final flat = <AppNavItem>[];
  for (final group in sections) {
    for (var index = 0; index < group.items.length; index++) {
      final item = group.items[index];
      flat.add(
        item.copyWith(section: index == 0 ? group.title : null),
      );
    }
  }
  return flat;
}

final List<AppNavItem> kAppNavItems = buildFlatNavItems(kAppNavSections);

/// Secções filtradas por permissão (hierarquia preservada).
List<AppNavSection> visibleNavSectionsForAccess(SessionAccessState access) {
  final sections = <AppNavSection>[];
  for (final group in kAppNavSections) {
    final allowedItems = group.items
        .where((item) => _canAccessNavItem(item, access))
        .toList(growable: false);
    if (allowedItems.isEmpty) continue;
    sections.add(AppNavSection(title: group.title, items: allowedItems));
  }
  return sections;
}

List<AppNavItem> visibleNavItemsForAccess(SessionAccessState access) {
  return buildFlatNavItems(visibleNavSectionsForAccess(access));
}

/// Primeiro item de menu permitido — usado como home pós-login.
String homePathForAccess(SessionAccessState access) {
  if (access.viewState == SessionAccessViewState.loaded) {
    for (final group in kAppNavSections) {
      for (final item in group.items) {
        final module = item.permissionModule;
        if (module == null || access.can(module, item.permissionAction)) {
          return item.path;
        }
      }
    }
  }
  return AppRoutePaths.dashboard;
}

String homePathForPermissions(UserEffectivePermissions? permissions) {
  if (permissions == null) return AppRoutePaths.dashboard;
  return homePathForAccess(
    SessionAccessState(
      permissions: permissions,
      viewState: SessionAccessViewState.loaded,
    ),
  );
}

AppNavItem? navItemForPath(String path) {
  AppNavItem? best;
  var bestLen = -1;
  for (final group in kAppNavSections) {
    for (final item in group.items) {
      final match = path == item.path || path.startsWith('${item.path}/');
      if (match && item.path.length > bestLen) {
        best = item;
        bestLen = item.path.length;
      }
    }
  }
  return best;
}

/// `true` se a rota ainda não deve ser bloqueada, ou se o user tem permissão.
bool isNavPathAllowedForAccess(String path, SessionAccessState access) {
  if (access.viewState != SessionAccessViewState.loaded) return true;
  final item = navItemForPath(path);
  if (item == null || item.permissionModule == null) return true;
  return access.can(item.permissionModule!, item.permissionAction);
}

String? navSectionTitleForPath(String path) {
  for (final group in kAppNavSections) {
    if (group.items.any((item) => item.path == path)) {
      return group.title;
    }
  }
  return AppRouteTitles.sectionFor(path);
}

String navTagForPath(String path) {
  return navSectionTitleForPath(path) ?? AppNavSections.dashboard;
}
