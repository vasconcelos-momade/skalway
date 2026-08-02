import { DashboardController } from "../../modules/tenant/dashboard/presentation/dashboard.controller";
import {
  tenantAuthMiddleware,
  tenantBranchContextMiddleware,
  getTenantAuth,
  requireAnyPermission,
  requirePermission,
} from "../../shared/http/auth-middlewares";
import type { Router } from "../../shared/http/router";

const dashboardController = new DashboardController();

export function registerDashboardRoutes(router: Router, prefix: string): void {
  const relatoriosAuth = [
    tenantAuthMiddleware(),
    tenantBranchContextMiddleware(),
    requirePermission("RELATORIOS", "VIEW"),
  ] as const;

  // Receita/Faturamento (grupo Financeiro) reutiliza o painel financeiro;
  // CAIXA precisa de leitura sem VIEW em RELATORIOS.
  const financeDashboardAuth = [
    tenantAuthMiddleware(),
    tenantBranchContextMiddleware(),
    requireAnyPermission([
      ["RELATORIOS", "VIEW"],
      ["CAIXA", "VIEW"],
    ]),
  ] as const;

  const pharmacyDashboardAuth = [
    tenantAuthMiddleware(),
    tenantBranchContextMiddleware(),
    requirePermission("DASHBOARD_FARMACIA", "VIEW"),
  ] as const;

  const cashierDashboardAuth = [
    tenantAuthMiddleware(),
    tenantBranchContextMiddleware(),
    requirePermission("DASHBOARD_CAIXA", "VIEW"),
  ] as const;

  router.get(
    `${prefix}/tenant/dashboard/executivo`,
    ...relatoriosAuth,
    async (context) => dashboardController.executive(context.req),
  );

  router.get(
    `${prefix}/tenant/dashboard/executivo/tables`,
    ...relatoriosAuth,
    async (context) => dashboardController.executiveTable(context.req),
  );

  router.get(
    `${prefix}/tenant/dashboard/financeiro`,
    ...financeDashboardAuth,
    async (context) =>
      dashboardController.finance(context.req, getTenantAuth(context).userId),
  );

  router.get(
    `${prefix}/tenant/dashboard/financeiro/tables`,
    ...financeDashboardAuth,
    async (context) =>
      dashboardController.financeTable(context.req, getTenantAuth(context).userId),
  );

  router.get(
    `${prefix}/tenant/dashboard/farmacia`,
    ...pharmacyDashboardAuth,
    async (context) =>
      dashboardController.pharmacy(context.req, getTenantAuth(context).userId),
  );

  router.get(
    `${prefix}/tenant/dashboard/farmacia/tables`,
    ...pharmacyDashboardAuth,
    async (context) =>
      dashboardController.pharmacyTable(context.req, getTenantAuth(context).userId),
  );

  router.get(
    `${prefix}/tenant/dashboard/stock`,
    ...relatoriosAuth,
    async (context) => dashboardController.stock(context.req),
  );

  router.get(
    `${prefix}/tenant/dashboard/stock/tables`,
    ...relatoriosAuth,
    async (context) => dashboardController.stockTable(context.req),
  );

  router.get(
    `${prefix}/tenant/dashboard/caixa`,
    ...cashierDashboardAuth,
    async (context) =>
      dashboardController.cashier(context.req, getTenantAuth(context).userId),
  );

  router.get(
    `${prefix}/tenant/dashboard/caixa/tables`,
    ...cashierDashboardAuth,
    async (context) =>
      dashboardController.cashierTable(context.req, getTenantAuth(context).userId),
  );
}
