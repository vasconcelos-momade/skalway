/// Caminhos GoRouter (paths) e metadados de navegação.
abstract final class AppRoutePaths {
  AppRoutePaths._();

  static const String app = '/app';

  static const String login = '/login';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authTenantSelection = '/auth/tenant-selection';
  /// Legado — redirect para [authTenantSelection].
  static const String authTenant = authTenantSelection;

  static const String dashboard = '/app/dashboard';
  static const String dashboardPharmacy = '/app/dashboard/pharmacy';
  static const String dashboardFinance = '/app/dashboard/finance';
  static const String dashboardStock = '/app/dashboard/stock';

  static const String pharmacyStock = '/app/pharmacy/stock';
  static const String regulatoryHub = '/app/regulatory';
  static const String financeHub = '/app/financial';
  static const String auditHub = '/app/audit';
  static const String settingsHub = '/app/settings';

  static const String pos = '/app/pos';

  static const String products = '/app/products';
  static const String pharmacyCategories = '/app/pharmacy/categories';
  static const String pharmacyLots = '/app/pharmacy/lots';
  static const String pharmacyExpiry = '/app/pharmacy/expiry';
  static const String pharmacyFefo = '/app/pharmacy/fefo';

  static const String regulatory = '/app/regulatory';
  static const String psychotropics = '/app/psychotropics';
  static const String recipes = '/app/recipes';
  static const String recipesBook = '/app/recipes/book';

  static const String financial = '/app/financial';
  static const String financeCashflow = '/app/finance/cashflow';
  static const String financeExpenses = '/app/finance/expenses';

  static const String audit = '/app/audit';
  static const String auditTimeline = '/app/audit/timeline';
  static const String auditLogs = '/app/audit/logs';
  static const String auditPsych = '/app/audit/psychotropics';

  static const String purchasing = '/app/purchasing';
  static const String comprasLegacy = '/compras';

  static const String reports = '/app/reports';

  static const String stockMovements = '/app/stock/movements';
  static const String stockRequisitions = '/app/stock/requests';
  static const String stockRequisitionsLegacy = '/app/stock/requisicoes';
  static const String stockTransfersLegacy = '/app/stock/transferencias';
  static const String stockInventory = '/app/stock/inventory';
  static const String stockSuppliers = '/app/stock/suppliers';
  static const String stockPurchases = '/app/stock/purchases';
  static const String stockPurchaseSuggestions = '/app/stock/purchase-suggestions';

  static const String salesCustomers = '/app/sales/customers';
  static const String salesInvoices = '/app/sales/invoices';
  static const String salesProformaInvoices = '/app/sales/proforma-invoices';
  static const String salesHistory = '/app/sales/history';

  static const String users = '/app/users';
  static const String userProfiles = '/app/users/profiles';
  static const String userPermissions = '/app/users/permissions';

  static const String settings = '/app/settings';
  static const String settingsPrinters = '/app/settings/printers';
  static const String settingsTerminals = '/app/settings/terminals';
  static const String settingsSync = '/app/settings/sync';

  // Legado (redirect no router)
  static const String legacyDashboard = '/dashboard';
  static const String legacyPos = '/pos';
  static const String legacyProducts = '/products';

  // Painel administrativo SaaS (plataforma central)
  /// Legado — redirect para [login].
  static const String platformLogin = '/platform/login';
  static const String platformDashboard = '/platform/dashboard';
  static const String platformTenants = '/platform/tenants';
  static const String platformTenantDetail = '/platform/tenants/:tenantId';
  static const String platformBranches = '/platform/branches';
  static const String platformPlans = '/platform/plans';
  static const String platformSubscriptions = '/platform/subscriptions';
  static const String platformInvoices = '/platform/invoices';
  static const String platformPayments = '/platform/payments';
  static const String platformDevices = '/platform/devices';
  static const String platformSync = '/platform/sync';
  static const String platformAudit = '/platform/audit';
  static const String platformUsers = '/platform/users';
  static const String platformSettings = '/platform/settings';

  static String platformTenantDetailPath(String tenantId) =>
      '/platform/tenants/$tenantId';

  static bool isPlatformRoute(String path) => path.startsWith('/platform');
  static bool isTenantAppRoute(String path) =>
      path.startsWith(app) || path == legacyPos;
}

/// Títulos humanos para topbar / breadcrumbs.
abstract final class AppRouteTitles {
  AppRouteTitles._();

  static String titleFor(String path) {
    return switch (path) {
      AppRoutePaths.login => 'Autenticação',
      AppRoutePaths.authForgotPassword => 'Recuperar palavra-passe',
      AppRoutePaths.authTenantSelection => 'Selecção de unidade',
      AppRoutePaths.dashboard => 'Executivo',
      AppRoutePaths.dashboardPharmacy => 'Farmácia',
      AppRoutePaths.dashboardFinance => 'Financeiro',
      AppRoutePaths.dashboardStock => 'Stock',
      AppRoutePaths.pos => 'POS / Caixa',
      AppRoutePaths.products => 'Produtos',
      AppRoutePaths.pharmacyCategories => 'Categorias',
      AppRoutePaths.pharmacyLots => 'Estoque & Lotes',
      AppRoutePaths.pharmacyExpiry => 'Validades',
      AppRoutePaths.pharmacyFefo => 'FEFO',
      AppRoutePaths.regulatory => 'Sanitário / Alertas',
      AppRoutePaths.psychotropics => 'Livro de Psicotrópicos',
      AppRoutePaths.recipes => 'Receitas',
      AppRoutePaths.recipesBook => 'Livro de Receitas',
      AppRoutePaths.financial => 'Visão Geral',
      AppRoutePaths.financeCashflow => 'Fluxo de Caixa',
      AppRoutePaths.financeExpenses => 'Despesas',
      AppRoutePaths.audit => 'Visão Geral',
      AppRoutePaths.auditTimeline => 'Cronologia',
      AppRoutePaths.auditLogs => 'Logs',
      AppRoutePaths.auditPsych => 'Auditoria de Psicotrópicos',
      AppRoutePaths.purchasing => 'Compras',
      AppRoutePaths.comprasLegacy => 'Compras',
      AppRoutePaths.reports => 'Relatórios',
      AppRoutePaths.stockMovements => 'Movimentos',
      AppRoutePaths.stockRequisitions => 'Compras',
      AppRoutePaths.stockRequisitionsLegacy => 'Compras',
      AppRoutePaths.stockTransfersLegacy => 'Compras',
      AppRoutePaths.stockInventory => 'Inventário',
      AppRoutePaths.stockSuppliers => 'Fornecedores',
      AppRoutePaths.stockPurchases => 'Compras',
      AppRoutePaths.stockPurchaseSuggestions => 'Sugestão de Compra',
      AppRoutePaths.salesCustomers => 'Clientes',
      AppRoutePaths.salesInvoices => 'Faturas',
      AppRoutePaths.salesProformaInvoices => 'Faturas Proforma',
      AppRoutePaths.salesHistory => 'Histórico de Vendas',
      AppRoutePaths.users => 'Utilizadores',
      AppRoutePaths.userProfiles => 'Perfis',
      AppRoutePaths.userPermissions => 'Permissões',
      AppRoutePaths.settings => 'Definições',
      AppRoutePaths.settingsPrinters => 'Impressoras',
      AppRoutePaths.settingsTerminals => 'Terminais',
      AppRoutePaths.settingsSync => 'Sincronização',
      AppRoutePaths.platformDashboard => 'Dashboard',
      AppRoutePaths.platformTenants => 'Clientes',
      _ => path.replaceAll('/', ' ').trim(),
    };
  }

  static String sectionFor(String path) {
    if (path.startsWith('/app/dashboard') || path == AppRoutePaths.legacyDashboard) {
      return 'Dashboard';
    }
    if (path.startsWith('/app/pharmacy') || path == AppRoutePaths.products) {
      return 'Farmácia';
    }
    if (path.startsWith('/app/sales') || path == AppRoutePaths.pos) {
      return 'Terminal';
    }
    if (path.startsWith('/app/stock')) return 'Farmácia';
    if (path == AppRoutePaths.regulatory ||
        path == AppRoutePaths.psychotropics ||
        path == AppRoutePaths.recipes ||
        path == AppRoutePaths.recipesBook) {
      return 'Regulatório';
    }
    if (path.startsWith('/app/finance') || path == AppRoutePaths.financial) {
      return 'Financeiro';
    }
    if (path.startsWith('/app/audit') || path == AppRoutePaths.audit) {
      return 'Auditoria';
    }
    if (path.startsWith('/app/users')) {
      return 'Administração';
    }
    if (path.startsWith('/app/settings')) {
      return 'Sistema';
    }
    if (path.startsWith('/auth')) {
      return 'Conta';
    }
    if (path.startsWith('/platform')) {
      return 'Plataforma';
    }
    if (path == AppRoutePaths.purchasing) {
      return 'Farmácia';
    }
    return 'Pharma ERP';
  }
}
