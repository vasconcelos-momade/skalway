export const TENANT_PERMISSION_ROLES = [
  "ADMIN",
  "GERENTE",
  "FARMACEUTICO",
  "DIRETOR_TECNICO",
  "CAIXA",
] as const;

export type TenantPermissionRole = (typeof TENANT_PERMISSION_ROLES)[number];

export const TENANT_SYSTEM_MODULES = [
  "REQUISICOES",
  "COMPRAS",
  "PRODUTOS",
  "LOTES",
  "INVENTARIO",
  "FORNECEDORES",
  "CLIENTES",
  "PROFORMA_INVOICES",
  "POS",
  "RELATORIOS",
  "UTILIZADORES",
  "CONFIGURACOES",
  "DASHBOARD_FARMACIA",
  "DASHBOARD_CAIXA",
  "CAIXA",
  // Legado, mantido para compatibilidade de dados.
  "FATURAS",
  "ESTOQUE",
  "PSICOTROPICOS",
  "AUDITORIA",
] as const;

export type TenantSystemModule = (typeof TENANT_SYSTEM_MODULES)[number];

export const TENANT_PERMISSION_ACTIONS = [
  "VIEW",
  "CREATE",
  "UPDATE",
  "DELETE",
  "APPROVE",
  "REJECT",
  "CANCEL",
  "EXPORT",
  "CREATE_LOTE",
  "ADJUST_STOCK",
  "CLOSE_SHIFT",
  // Legado, mantido para compatibilidade de dados.
  "EDIT",
] as const;

export type TenantPermissionAction = (typeof TENANT_PERMISSION_ACTIONS)[number];

export type PermissionGrant = {
  module: TenantSystemModule;
  actions: readonly TenantPermissionAction[];
};

const ALL_STANDARD_MODULES = [
  "REQUISICOES",
  "COMPRAS",
  "PRODUTOS",
  "LOTES",
  "INVENTARIO",
  "FORNECEDORES",
  "CLIENTES",
  "PROFORMA_INVOICES",
  "POS",
  "RELATORIOS",
  "UTILIZADORES",
  "CONFIGURACOES",
  "DASHBOARD_FARMACIA",
  "DASHBOARD_CAIXA",
  "CAIXA",
] as const satisfies readonly TenantSystemModule[];

const ALL_STANDARD_ACTIONS = [
  "VIEW",
  "CREATE",
  "UPDATE",
  "DELETE",
  "APPROVE",
  "REJECT",
  "CANCEL",
  "EXPORT",
  "CREATE_LOTE",
  "ADJUST_STOCK",
  "CLOSE_SHIFT",
] as const satisfies readonly TenantPermissionAction[];

const FULL_ACCESS_GRANTS: readonly PermissionGrant[] = ALL_STANDARD_MODULES.map(
  (module) => ({ module, actions: ALL_STANDARD_ACTIONS }),
);

export const CRITICAL_PERMISSION_ACTIONS = new Set<TenantPermissionAction>([
  "APPROVE",
  "REJECT",
  "CANCEL",
  "DELETE",
  "EXPORT",
  "CREATE_LOTE",
  "ADJUST_STOCK",
  "CLOSE_SHIFT",
]);

export const MODULE_PERMISSION_ALIASES: Record<TenantSystemModule, readonly TenantSystemModule[]> = {
  REQUISICOES: ["REQUISICOES", "ESTOQUE"],
  COMPRAS: ["COMPRAS", "ESTOQUE"],
  PRODUTOS: ["PRODUTOS"],
  LOTES: ["LOTES", "ESTOQUE"],
  INVENTARIO: ["INVENTARIO", "ESTOQUE"],
  FORNECEDORES: ["FORNECEDORES", "ESTOQUE"],
  CLIENTES: ["CLIENTES"],
  PROFORMA_INVOICES: ["PROFORMA_INVOICES", "CLIENTES", "POS"],
  POS: ["POS", "FATURAS", "CAIXA"],
  RELATORIOS: ["RELATORIOS", "AUDITORIA", "PSICOTROPICOS"],
  UTILIZADORES: ["UTILIZADORES"],
  CONFIGURACOES: ["CONFIGURACOES"],
  DASHBOARD_FARMACIA: ["DASHBOARD_FARMACIA"],
  DASHBOARD_CAIXA: ["DASHBOARD_CAIXA"],
  CAIXA: ["CAIXA", "POS"],
  FATURAS: ["FATURAS", "POS"],
  ESTOQUE: ["ESTOQUE", "REQUISICOES", "COMPRAS", "LOTES", "INVENTARIO", "FORNECEDORES"],
  PSICOTROPICOS: ["PSICOTROPICOS", "RELATORIOS"],
  AUDITORIA: ["AUDITORIA", "RELATORIOS"],
};

export const ACTION_PERMISSION_ALIASES: Record<TenantPermissionAction, readonly TenantPermissionAction[]> = {
  VIEW: ["VIEW"],
  CREATE: ["CREATE"],
  UPDATE: ["UPDATE", "EDIT"],
  DELETE: ["DELETE"],
  APPROVE: ["APPROVE"],
  REJECT: ["REJECT"],
  CANCEL: ["CANCEL"],
  EXPORT: ["EXPORT"],
  CREATE_LOTE: ["CREATE_LOTE"],
  ADJUST_STOCK: ["ADJUST_STOCK"],
  CLOSE_SHIFT: ["CLOSE_SHIFT"],
  EDIT: ["EDIT", "UPDATE"],
};

export const DEFAULT_ROLE_PERMISSION_MATRIX: Record<TenantPermissionRole, readonly PermissionGrant[]> = {
  // Acesso total ao sistema.
  ADMIN: FULL_ACCESS_GRANTS,
  GERENTE: FULL_ACCESS_GRANTS,
  DIRETOR_TECNICO: FULL_ACCESS_GRANTS,
  // Dashboard Farmácia + Terminal + Farmácia.
  FARMACEUTICO: [
    { module: "DASHBOARD_FARMACIA", actions: ["VIEW"] },
    { module: "POS", actions: ALL_STANDARD_ACTIONS },
    { module: "PROFORMA_INVOICES", actions: ALL_STANDARD_ACTIONS },
    { module: "CLIENTES", actions: ALL_STANDARD_ACTIONS },
    { module: "PRODUTOS", actions: ALL_STANDARD_ACTIONS },
    { module: "LOTES", actions: ALL_STANDARD_ACTIONS },
    { module: "INVENTARIO", actions: ALL_STANDARD_ACTIONS },
    { module: "COMPRAS", actions: ALL_STANDARD_ACTIONS },
    { module: "FORNECEDORES", actions: ALL_STANDARD_ACTIONS },
  ],
  // Dashboard do Caixa + Terminal + Financeiro (módulo CAIXA).
  CAIXA: [
    { module: "DASHBOARD_CAIXA", actions: ["VIEW"] },
    { module: "POS", actions: ["VIEW", "CREATE", "UPDATE", "CLOSE_SHIFT"] },
    { module: "PROFORMA_INVOICES", actions: ["VIEW", "CREATE", "UPDATE"] },
    { module: "CLIENTES", actions: ["VIEW", "CREATE", "UPDATE"] },
    { module: "CAIXA", actions: ["VIEW", "CREATE", "UPDATE", "CLOSE_SHIFT"] },
  ],
};

export function expandRolePermissionMatrix() {
  return (Object.entries(DEFAULT_ROLE_PERMISSION_MATRIX) as Array<
    [TenantPermissionRole, readonly PermissionGrant[]]
  >).flatMap(([role, grants]) =>
    grants.flatMap((grant) =>
      grant.actions.map((action) => ({
        role,
        module: grant.module,
        action,
      })),
    ),
  );
}

export function isCriticalPermissionAction(action: TenantPermissionAction): boolean {
  return CRITICAL_PERMISSION_ACTIONS.has(action);
}

export function isTenantSystemModule(value: string): value is TenantSystemModule {
  return TENANT_SYSTEM_MODULES.includes(value as TenantSystemModule);
}

export function isTenantPermissionAction(value: string): value is TenantPermissionAction {
  return TENANT_PERMISSION_ACTIONS.includes(value as TenantPermissionAction);
}

export function listStandardModules() {
  return [...ALL_STANDARD_MODULES];
}

export function listStandardActions() {
  return [...ALL_STANDARD_ACTIONS];
}
