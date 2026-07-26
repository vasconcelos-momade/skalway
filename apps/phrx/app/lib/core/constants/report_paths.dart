import 'report_keys.dart';

/// Endpoints HTTP dos relatórios, centralizados e alinhados com [ReportKeys].
abstract final class ReportPaths {
  ReportPaths._();

  static const expiry = '/reports/expiry';
  static const invoices = '/reports/invoices';
  static const salesHistory = '/reports/sales-history';
  static const customers = '/reports/customers';
  static const proformaInvoices = '/reports/proforma-invoices';
  static const dashboardExecutive = '/reports/dashboards/executive';
  static const dashboardFinance = '/reports/dashboards/finance';
  static const dashboardPharmacy = '/reports/dashboards/pharmacy';
  static const dashboardStock = '/reports/dashboards/stock';

  static const pharmacyProductsCatalog = '/reports/pharmacy/products/catalog';
  static const pharmacyProductsByCategory = '/reports/pharmacy/products/by-category';
  static const pharmacyProductsBySupplier = '/reports/pharmacy/products/by-supplier';
  static const pharmacyProductsBySubstancia = '/reports/pharmacy/products/by-substancia';
  static const pharmacyProductsNoStock = '/reports/pharmacy/products/no-stock';
  static const pharmacyProductsBelowMinStock = '/reports/pharmacy/products/below-min-stock';
  static const pharmacyProductsNearExpiry = '/reports/pharmacy/products/near-expiry';
  static const pharmacyProductsExpired = '/reports/pharmacy/products/expired';
  static const pharmacyProductsControlled = '/reports/pharmacy/products/controlled';
  static const pharmacyCategories = '/reports/pharmacy/categories';
  static const pharmacyLotsActive = '/reports/pharmacy/lots/active';
  static const pharmacyLotsExpired = '/reports/pharmacy/lots/expired';
  static const pharmacyFefoOverview = '/reports/pharmacy/fefo/overview';
  static const pharmacyFefoAudit = '/reports/pharmacy/fefo/audit';

  static const stockMovements = '/reports/stock/movements';
  static const stockMovementsEntrada = '/reports/stock/movements/entrada';
  static const stockMovementsSaida = '/reports/stock/movements/saida';
  static const stockMovementsAjuste = '/reports/stock/movements/ajuste';
  static const stockPurchaseSuggestions = '/reports/stock/purchase-suggestions';
  static const stockInventories = '/reports/stock/inventories';

  static const financeCashflow = '/reports/finance/cashflow';
  static const financeExpenses = '/reports/finance/expenses';
  static const financeAccountsReceivable = '/reports/finance/accounts-receivable';
  static const financeAccountsPayable = '/reports/finance/accounts-payable';

  static const regulatoryReceitas = '/reports/regulatory/receitas';
  static const regulatoryLivroReceitas = '/reports/regulatory/livro-receitas';
  static const regulatoryLivroPsicotropicos = '/reports/regulatory/livro-psicotropicos';
  static const regulatorySanitario = '/reports/regulatory/sanitario';

  static const auditDashboard = '/reports/audit/dashboard';
  static const auditLogs = '/reports/audit/logs';
  static const auditTimeline = '/reports/audit/timeline';
  static const auditBusinessEvents = '/reports/audit/business-events';
  static const auditPsychotropics = '/reports/audit/psychotropics';
  static const auditStock = '/reports/audit/stock';
  static const auditFinancial = '/reports/audit/financial';

  static const adminUsers = '/reports/admin/users';
  static const adminSessions = '/reports/admin/sessions';
  static const adminLastAccess = '/reports/admin/last-access';
  static const adminLoginHistory = '/reports/admin/login-history';
  static const adminUserActivity = '/reports/admin/user-activity';
  static const adminAccessAudit = '/reports/admin/access-audit';
  static const adminPermissionsMatrix = '/reports/admin/permissions-matrix';
  static const adminRoles = '/reports/admin/roles';

  static String invoice(String invoiceId) => '/reports/invoices/$invoiceId';
  static String proformaInvoice(String proformaInvoiceId) =>
      '/reports/proforma-invoices/$proformaInvoiceId';
  static String stockInventory(String inventarioId) =>
      '/reports/stock/inventories/$inventarioId';

  static const Map<String, String> byKey = {
    ReportKeys.expiry: expiry,
    ReportKeys.invoice: invoices,
    ReportKeys.invoiceList: invoices,
    ReportKeys.salesHistory: salesHistory,
    ReportKeys.customers: customers,
    ReportKeys.proformaInvoice: proformaInvoices,
    ReportKeys.proformaInvoiceList: proformaInvoices,
    ReportKeys.dashboardExecutive: dashboardExecutive,
    ReportKeys.dashboardFinance: dashboardFinance,
    ReportKeys.dashboardPharmacy: dashboardPharmacy,
    ReportKeys.dashboardStock: dashboardStock,
    ReportKeys.productsCatalog: pharmacyProductsCatalog,
    ReportKeys.productsByCategory: pharmacyProductsByCategory,
    ReportKeys.productsBySupplier: pharmacyProductsBySupplier,
    ReportKeys.productsBySubstancia: pharmacyProductsBySubstancia,
    ReportKeys.productsNoStock: pharmacyProductsNoStock,
    ReportKeys.productsBelowMinStock: pharmacyProductsBelowMinStock,
    ReportKeys.productsNearExpiry: pharmacyProductsNearExpiry,
    ReportKeys.productsExpired: pharmacyProductsExpired,
    ReportKeys.productsControlled: pharmacyProductsControlled,
    ReportKeys.categories: pharmacyCategories,
    ReportKeys.lotsActive: pharmacyLotsActive,
    ReportKeys.lotsExpired: pharmacyLotsExpired,
    ReportKeys.fefoOverview: pharmacyFefoOverview,
    ReportKeys.fefoAudit: pharmacyFefoAudit,
    ReportKeys.stockMovements: stockMovements,
    ReportKeys.stockMovementsEntrada: stockMovementsEntrada,
    ReportKeys.stockMovementsSaida: stockMovementsSaida,
    ReportKeys.stockMovementsAjuste: stockMovementsAjuste,
    ReportKeys.purchaseSuggestions: stockPurchaseSuggestions,
    ReportKeys.inventories: stockInventories,
    ReportKeys.financeCashflow: financeCashflow,
    ReportKeys.financeExpenses: financeExpenses,
    ReportKeys.financeAccountsReceivable: financeAccountsReceivable,
    ReportKeys.financeAccountsPayable: financeAccountsPayable,
    ReportKeys.regulatoryReceitas: regulatoryReceitas,
    ReportKeys.regulatoryLivroReceitas: regulatoryLivroReceitas,
    ReportKeys.regulatoryLivroPsicotropicos: regulatoryLivroPsicotropicos,
    ReportKeys.regulatorySanitario: regulatorySanitario,
    ReportKeys.auditDashboard: auditDashboard,
    ReportKeys.auditLogs: auditLogs,
    ReportKeys.auditTimeline: auditTimeline,
    ReportKeys.auditBusinessEvents: auditBusinessEvents,
    ReportKeys.auditPsychotropics: auditPsychotropics,
    ReportKeys.auditStock: auditStock,
    ReportKeys.auditFinancial: auditFinancial,
    ReportKeys.adminUsers: adminUsers,
    ReportKeys.adminSessions: adminSessions,
    ReportKeys.adminLastAccess: adminLastAccess,
    ReportKeys.adminLoginHistory: adminLoginHistory,
    ReportKeys.adminUserActivity: adminUserActivity,
    ReportKeys.adminAccessAudit: adminAccessAudit,
    ReportKeys.adminPermissionsMatrix: adminPermissionsMatrix,
    ReportKeys.adminRoles: adminRoles,
  };

  static String forKey(String reportKey) {
    final path = byKey[reportKey];
    if (path == null) {
      throw ArgumentError.value(reportKey, 'reportKey', 'Report key sem path definido');
    }
    return path;
  }
}
