import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../modules/admin/users/presentation/pages/users_page.dart';
import '../../modules/audit/presentation/pages/audit_hub_page.dart';
import '../../modules/audit/presentation/pages/audit_logs_page.dart';
import '../../modules/sales/customers/presentation/pages/customers_page.dart';
import '../../modules/sales/history/presentation/pages/sales_history_page.dart';
import '../../modules/auth/presentation/pages/forgot_password_page.dart';
import '../../modules/auth/presentation/pages/login_page.dart';
import '../../modules/auth/presentation/pages/tenant_select_page.dart';
import '../../modules/central/presentation/pages/platform_dashboard_page.dart';
import '../../modules/central/presentation/pages/platform_list_page.dart';
import '../../modules/central/presentation/pages/platform_tenant_detail_page.dart';
import '../../modules/central/presentation/pages/platform_tenants_page.dart';
import '../../modules/central/presentation/shell/platform_main_shell.dart';
import '../../modules/dashboard/presentation/pages/executive_dashboard_page.dart';
import '../../modules/dashboard/presentation/pages/finance_dashboard_page.dart';
import '../../modules/dashboard/presentation/pages/pharmacy_dashboard_page.dart';
import '../../modules/dashboard/presentation/pages/stock_dashboard_page.dart';
import '../../modules/finance/presentation/pages/cashflow_page.dart';
import '../../modules/finance/presentation/pages/finance_hub_page.dart';
import '../../modules/pharmacy/presentation/pages/pharmacy_stock_hub_page.dart';
import '../../modules/pharmacy/presentation/pages/regulatory_hub_page.dart';
import '../../modules/pharmacy/prescriptions/presentation/pages/recipes_book_page.dart';
import '../../modules/pharmacy/psychotropics/presentation/pages/psychotropics_book_page.dart';
import '../../modules/pharmacy/sanitary/presentation/pages/regulatory_page.dart';
import '../../modules/pharmacy/products/presentation/pages/products_page.dart';
import '../../modules/pharmacy/categories/presentation/pages/categories_page.dart';
import '../../modules/sales/proforma_invoices/presentation/pages/proforma_invoices_page.dart';
import '../../modules/sales/invoices/presentation/pages/invoices_page.dart';
import '../../modules/sales/pdv/presentation/pages/pdv_page.dart';
import '../../modules/stock/presentation/pages/fornecedores_page.dart';
import '../../modules/stock/presentation/pages/inventory_hub_page.dart';
import '../../modules/stock/presentation/pages/purchase_suggestions_page.dart';
import '../../modules/stock/presentation/pages/movimentacoes_hub_page.dart';
import '../../modules/settings/presentation/pages/printers_page.dart';
import '../../modules/settings/presentation/pages/settings_hub_page.dart';
import '../../modules/settings/presentation/pages/terminals_page.dart';
import '../../shared/layouts/app_main_shell.dart';
import '../../shared/layouts/pos_shell_layout.dart';
import '../app_observer.dart';
import '../providers/auth_session_notifier.dart';
import '../providers/session_access_notifier.dart';
import 'router_refresh.dart';
import 'routes.dart';

bool _isPublicAuthRoute(String loc) {
  return loc == AppRoutePaths.login ||
      loc == AppRoutePaths.authForgotPassword;
}

bool _isTenantSelectionRoute(String loc) =>
    loc == AppRoutePaths.authTenantSelection || loc == '/auth/tenant';

bool _isTenantAppRoute(String loc) =>
    loc.startsWith(AppRoutePaths.app) || loc == AppRoutePaths.legacyPos;

bool _isLegacyTenantRoute(String loc) {
  if (loc.startsWith('/platform') || loc.startsWith('/auth') || loc == AppRoutePaths.login) {
    return false;
  }
  return !loc.startsWith('/app') &&
      loc != AppRoutePaths.legacyPos &&
      loc != AppRoutePaths.comprasLegacy;
}

bool _isAdministrationRoute(String loc) => loc == AppRoutePaths.users;

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshProvider);

  return GoRouter(
    initialLocation: AppRoutePaths.login,
    refreshListenable: refresh,
    observers: [AppNavigatorObserver()],
    redirect: (context, state) {
      final auth = ref.read(authSessionProvider);
      final access = ref.read(sessionAccessProvider);
      final loc = state.matchedLocation;

      if (auth.isBootstrapping) {
        return null;
      }

      // ── Rotas da plataforma SaaS (SUPER_ADMIN) ─────────────────────────
      if (AppRoutePaths.isPlatformRoute(loc)) {
        if (loc == AppRoutePaths.platformLogin) {
          return AppRoutePaths.login;
        }
        if (!auth.isAuthenticated) {
          return AppRoutePaths.login;
        }
        if (!auth.isSuperAdmin) {
          return auth.hasTenantContext
              ? AppRoutePaths.dashboard
              : AppRoutePaths.authTenantSelection;
        }
        if (auth.hasTenantContext) {
          return AppRoutePaths.platformDashboard;
        }
        return null;
      }

      // Legado /auth/tenant → /auth/tenant-selection
      if (loc == '/auth/tenant') {
        return AppRoutePaths.authTenantSelection;
      }

      // ── Rotas tenant (/app/*) ───────────────────────────────────────────
      if (!auth.isAuthenticated) {
        if (_isPublicAuthRoute(loc)) return null;
        return AppRoutePaths.login;
      }

      if (auth.isSuperAdmin && !auth.hasTenantContext) {
        if (_isTenantAppRoute(loc) || _isLegacyTenantRoute(loc)) {
          return AppRoutePaths.platformDashboard;
        }
      }

      if (auth.isTenantRole && !auth.hasTenantContext) {
        if (_isTenantSelectionRoute(loc)) return null;
        if (_isPublicAuthRoute(loc)) return AppRoutePaths.authTenantSelection;
        if (_isTenantAppRoute(loc) || _isLegacyTenantRoute(loc)) {
          return AppRoutePaths.authTenantSelection;
        }
      }

      if (loc == AppRoutePaths.login ||
          loc == AppRoutePaths.authForgotPassword ||
          _isTenantSelectionRoute(loc)) {
        if (auth.isSuperAdmin) return AppRoutePaths.platformDashboard;
        if (auth.hasTenantContext) return AppRoutePaths.dashboard;
        if (_isTenantSelectionRoute(loc)) return null;
        return AppRoutePaths.authTenantSelection;
      }

      if (_isAdministrationRoute(loc) && !access.isResolved) {
        return null;
      }

      if (_isAdministrationRoute(loc) && !access.canAccessAdministration) {
        return AppRoutePaths.dashboard;
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutePaths.legacyDashboard,
        redirect: (context, state) => AppRoutePaths.dashboard,
      ),
      GoRoute(
        path: AppRoutePaths.legacyPos,
        redirect: (context, state) => AppRoutePaths.pos,
      ),
      GoRoute(
        path: AppRoutePaths.legacyProducts,
        redirect: (context, state) => AppRoutePaths.products,
      ),
      GoRoute(
        path: AppRoutePaths.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutePaths.authForgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutePaths.authTenantSelection,
        name: 'tenant-selection',
        builder: (context, state) => const TenantSelectPage(),
      ),
      GoRoute(
        path: AppRoutePaths.platformLogin,
        redirect: (context, state) => AppRoutePaths.login,
      ),
      ShellRoute(
        builder: (context, state, child) => PlatformMainShell(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutePaths.platformDashboard,
            name: 'platform-dashboard',
            builder: (context, state) => const PlatformDashboardPage(),
          ),
          GoRoute(
            path: AppRoutePaths.platformTenants,
            name: 'platform-tenants',
            builder: (context, state) => const PlatformTenantsPage(),
          ),
          GoRoute(
            path: AppRoutePaths.platformTenantDetail,
            name: 'platform-tenant-detail',
            builder: (context, state) => PlatformTenantDetailPage(
              tenantId: state.pathParameters['tenantId']!,
            ),
          ),
          GoRoute(
            path: AppRoutePaths.platformBranches,
            name: 'platform-branches',
            builder: (context, state) => const PlatformListPage(
              title: 'Filiais',
              subtitle: 'Todas as filiais dos clientes.',
              placeholder: 'Lista global de filiais',
            ),
          ),
          GoRoute(
            path: AppRoutePaths.platformPlans,
            name: 'platform-plans',
            builder: (context, state) => const PlatformListPage(
              title: 'Planos',
              subtitle: 'Planos de subscrição disponíveis.',
              placeholder: 'Gestão de planos',
            ),
          ),
          GoRoute(
            path: AppRoutePaths.platformSubscriptions,
            name: 'platform-subscriptions',
            builder: (context, state) => const PlatformListPage(
              title: 'Assinaturas',
              subtitle: 'Subscrições activas na plataforma.',
              placeholder: 'Lista de assinaturas',
            ),
          ),
          GoRoute(
            path: AppRoutePaths.platformInvoices,
            name: 'platform-invoices',
            builder: (context, state) => const PlatformListPage(
              title: 'Faturas',
              subtitle: 'Faturação SaaS consolidada.',
              invoices: true,
            ),
          ),
          GoRoute(
            path: AppRoutePaths.platformPayments,
            name: 'platform-payments',
            builder: (context, state) => const PlatformListPage(
              title: 'Pagamentos',
              subtitle: 'Pagamentos manuais e confirmações.',
              payments: true,
            ),
          ),
          GoRoute(
            path: AppRoutePaths.platformDevices,
            name: 'platform-devices',
            builder: (context, state) => const PlatformListPage(
              title: 'Dispositivos',
              subtitle: 'Terminais e dispositivos registados.',
              placeholder: 'Monitorização de dispositivos',
            ),
          ),
          GoRoute(
            path: AppRoutePaths.platformSync,
            name: 'platform-sync',
            builder: (context, state) => const PlatformListPage(
              title: 'Sincronização',
              subtitle: 'Estado de sync entre filiais e central.',
              placeholder: 'Painel de sincronização',
            ),
          ),
          GoRoute(
            path: AppRoutePaths.platformAudit,
            name: 'platform-audit',
            builder: (context, state) => const PlatformListPage(
              title: 'Auditoria',
              subtitle: 'Trilho de auditoria da plataforma.',
              placeholder: 'Logs de auditoria central',
            ),
          ),
          GoRoute(
            path: AppRoutePaths.platformUsers,
            name: 'platform-users',
            builder: (context, state) => const PlatformListPage(
              title: 'Utilizadores',
              subtitle: 'Utilizadores da plataforma central.',
              placeholder: 'Gestão de utilizadores central',
            ),
          ),
          GoRoute(
            path: AppRoutePaths.platformSettings,
            name: 'platform-settings',
            builder: (context, state) => const PlatformListPage(
              title: 'Configurações',
              subtitle: 'Parâmetros globais da plataforma.',
              placeholder: 'Configurações SaaS',
            ),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => AppMainShell(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutePaths.dashboard,
            name: 'dashboard',
            builder: (context, state) => const ExecutiveDashboardPage(),
          ),
          GoRoute(
            path: AppRoutePaths.dashboardPharmacy,
            name: 'dashboard-pharmacy',
            builder: (context, state) => const PharmacyDashboardPage(),
          ),
          GoRoute(
            path: AppRoutePaths.dashboardFinance,
            name: 'dashboard-finance',
            builder: (context, state) => const FinanceDashboardPage(),
          ),
          GoRoute(
            path: AppRoutePaths.dashboardStock,
            name: 'dashboard-stock',
            builder: (context, state) => const StockDashboardPage(),
          ),
          GoRoute(
            path: AppRoutePaths.products,
            name: 'products',
            builder: (context, state) => const ProductsPage(),
          ),
          GoRoute(
            path: AppRoutePaths.pharmacyCategories,
            name: 'pharmacy-categories',
            builder: (context, state) => const CategoriesPage(),
          ),
          GoRoute(
            path: AppRoutePaths.pharmacyStock,
            name: 'pharmacy-stock',
            builder: (context, state) => const PharmacyStockHubPage(),
          ),
          GoRoute(
            path: AppRoutePaths.pharmacyLots,
            redirect: (context, state) => AppRoutePaths.pharmacyStock,
          ),
          GoRoute(
            path: AppRoutePaths.pharmacyExpiry,
            redirect: (context, state) => AppRoutePaths.pharmacyStock,
          ),
          GoRoute(
            path: AppRoutePaths.pharmacyFefo,
            redirect: (context, state) => AppRoutePaths.pharmacyStock,
          ),
          GoRoute(
            path: AppRoutePaths.regulatoryHub,
            name: 'regulatory-hub',
            builder: (context, state) => const RegulatoryHubPage(),
          ),
          GoRoute(
            path: AppRoutePaths.regulatory,
            name: 'regulatory',
            builder: (context, state) => const RegulatoryPage(),
          ),
          GoRoute(
            path: AppRoutePaths.psychotropics,
            name: 'psychotropics',
            builder: (context, state) => const PsychotropicsBookPage(),
          ),
          GoRoute(
            path: AppRoutePaths.recipes,
            redirect: (context, state) => AppRoutePaths.recipesBook,
          ),
          GoRoute(
            path: AppRoutePaths.recipesBook,
            name: 'recipes-book',
            builder: (context, state) => const RecipesBookPage(),
          ),
          GoRoute(
            path: AppRoutePaths.financeHub,
            name: 'finance-hub',
            builder: (context, state) => const FinanceHubPage(),
          ),
          GoRoute(
            path: AppRoutePaths.financial,
            redirect: (context, state) => AppRoutePaths.financeCashflow,
          ),
          GoRoute(
            path: AppRoutePaths.financeCashflow,
            name: 'finance-cashflow',
            builder: (context, state) => const CashflowPage(),
          ),
          GoRoute(
            path: AppRoutePaths.financeExpenses,
            redirect: (context, state) => AppRoutePaths.financeHub,
          ),
          GoRoute(
            path: AppRoutePaths.auditHub,
            name: 'audit-hub',
            builder: (context, state) => const AuditHubPage(),
          ),
          GoRoute(
            path: AppRoutePaths.audit,
            redirect: (context, state) => AppRoutePaths.auditHub,
          ),
          GoRoute(
            path: AppRoutePaths.auditTimeline,
            redirect: (context, state) => AppRoutePaths.auditHub,
          ),
          GoRoute(
            path: AppRoutePaths.auditLogs,
            name: 'audit-logs',
            builder: (context, state) => const AuditLogsPage(),
          ),
          GoRoute(
            path: AppRoutePaths.auditPsych,
            redirect: (context, state) => AppRoutePaths.auditHub,
          ),
          GoRoute(
            path: AppRoutePaths.purchasing,
            redirect: (context, state) => AppRoutePaths.stockPurchaseSuggestions,
          ),
          GoRoute(
            path: AppRoutePaths.comprasLegacy,
            redirect: (context, state) => AppRoutePaths.stockPurchaseSuggestions,
          ),
          GoRoute(
            path: AppRoutePaths.reports,
            redirect: (context, state) => AppRoutePaths.dashboard,
          ),
          GoRoute(
            path: AppRoutePaths.stockMovements,
            name: 'stock-movements',
            builder: (context, state) => const MovimentacoesHubPage(),
          ),
          GoRoute(
            path: AppRoutePaths.stockRequisitions,
            redirect: (context, state) => AppRoutePaths.stockPurchaseSuggestions,
          ),
          GoRoute(
            path: AppRoutePaths.stockRequisitionsLegacy,
            redirect: (context, state) => AppRoutePaths.stockPurchaseSuggestions,
          ),
          GoRoute(
            path: AppRoutePaths.stockTransfersLegacy,
            redirect: (context, state) => AppRoutePaths.stockPurchaseSuggestions,
          ),
          GoRoute(
            path: AppRoutePaths.stockInventory,
            name: 'stock-inventory',
            builder: (context, state) => const InventoryHubPage(),
          ),
          GoRoute(
            path: AppRoutePaths.stockSuppliers,
            name: 'stock-suppliers',
            builder: (context, state) => const FornecedoresPage(),
          ),
          GoRoute(
            path: AppRoutePaths.stockPurchases,
            redirect: (context, state) => AppRoutePaths.stockPurchaseSuggestions,
          ),
          GoRoute(
            path: AppRoutePaths.stockPurchaseSuggestions,
            name: 'stock-purchase-suggestions',
            builder: (context, state) => const PurchaseSuggestionsPage(),
          ),
          GoRoute(
            path: AppRoutePaths.salesCustomers,
            name: 'sales-customers',
            builder: (context, state) => const CustomersPage(),
          ),
          GoRoute(
            path: AppRoutePaths.salesInvoices,
            name: 'sales-invoices',
            builder: (context, state) => const SalesInvoicesPage(),
          ),
          GoRoute(
            path: AppRoutePaths.salesProformaInvoices,
            name: 'sales-proforma-invoices',
            builder: (context, state) => const SalesProformaInvoicesPage(),
          ),
          GoRoute(
            path: AppRoutePaths.salesHistory,
            name: 'sales-history',
            builder: (context, state) => const SalesHistoryPage(),
          ),
          GoRoute(
            path: AppRoutePaths.users,
            name: 'users',
            builder: (context, state) => const UsersPage(),
          ),
          GoRoute(
            path: AppRoutePaths.userProfiles,
            redirect: (context, state) => AppRoutePaths.users,
          ),
          GoRoute(
            path: AppRoutePaths.userPermissions,
            redirect: (context, state) => AppRoutePaths.users,
          ),
          GoRoute(
            path: AppRoutePaths.settingsHub,
            name: 'settings-hub',
            builder: (context, state) => const SettingsHubPage(),
          ),
          GoRoute(
            path: AppRoutePaths.settings,
            redirect: (context, state) => AppRoutePaths.settingsHub,
          ),
          GoRoute(
            path: AppRoutePaths.settingsPrinters,
            name: 'settings-printers',
            builder: (context, state) => const PrintersPage(),
          ),
          GoRoute(
            path: AppRoutePaths.settingsTerminals,
            name: 'settings-terminals',
            builder: (context, state) => const TerminalsPage(),
          ),
          GoRoute(
            path: AppRoutePaths.settingsSync,
            redirect: (context, state) => AppRoutePaths.settingsHub,
          ),
        ],
      ),
      GoRoute(
        path: AppRoutePaths.pos,
        name: 'pos',
        builder: (context, state) => const PosShellLayout(child: PdvPage()),
      ),
    ],
  );
});
