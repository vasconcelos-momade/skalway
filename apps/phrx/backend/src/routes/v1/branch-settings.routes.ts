import { CentralBranchSettingsController } from "../../modules/central/presentation/controllers/central-branch-settings.controller";
import {
  tenantAuthMiddleware,
  tenantBranchContextMiddleware,
  requirePermission,
} from "../../shared/http/auth-middlewares";
import { auditMiddleware } from "../../shared/http/middlewares";
import type { RouteContext, Router } from "../../shared/http/router";

const controller = new CentralBranchSettingsController();

type ConfigAction = "VIEW" | "UPDATE";

function register(
  router: Router,
  method: "get" | "put" | "patch",
  path: string,
  action: ConfigAction,
  handler: (context: RouteContext) => Promise<Response>,
): void {
  if (action === "VIEW") {
    router[method](
      path,
      tenantAuthMiddleware(),
      tenantBranchContextMiddleware(),
      requirePermission("CONFIGURACOES", action),
      handler,
    );
    return;
  }

  router[method](
    path,
    tenantAuthMiddleware(),
    tenantBranchContextMiddleware(),
    requirePermission("CONFIGURACOES", action),
    auditMiddleware,
    handler,
  );
}

export function registerBranchSettingsRoutes(router: Router, prefix: string): void {
  // Aliases: /branches/:branchId/settings e /central/branches/:branchId/settings
  for (const base of [
    `${prefix}/branches/:branchId/settings`,
    `${prefix}/central/branches/:branchId/settings`,
  ]) {
    register(router, "get", base, "VIEW", (ctx) => controller.list(ctx));
    register(router, "put", base, "UPDATE", (ctx) => controller.update(ctx));
    register(router, "patch", base, "UPDATE", (ctx) => controller.update(ctx));
    register(router, "get", `${base}/invoice-profile`, "VIEW", (ctx) =>
      controller.invoiceProfile(ctx),
    );
  }

  // Atalho sem branchId no path — usa filial do contexto (x-branch-id).
  register(router, "get", `${prefix}/branch-settings`, "VIEW", (ctx) =>
    controller.list(ctx),
  );
  register(router, "put", `${prefix}/branch-settings`, "UPDATE", (ctx) =>
    controller.update(ctx),
  );
  register(router, "patch", `${prefix}/branch-settings`, "UPDATE", (ctx) =>
    controller.update(ctx),
  );
  register(
    router,
    "get",
    `${prefix}/branch-settings/invoice-profile`,
    "VIEW",
    (ctx) => controller.invoiceProfile(ctx),
  );
}
