import { describe, expect, test } from "bun:test";
import {
  DEFAULT_ROLE_PERMISSION_MATRIX,
  TENANT_PERMISSION_ROLES,
  expandRolePermissionMatrix,
  listStandardActions,
  listStandardModules,
  isCriticalPermissionAction,
} from "./permission.constants";

describe("DEFAULT_ROLE_PERMISSION_MATRIX", () => {
  test("define matriz para todos os roles tenant", () => {
    for (const role of TENANT_PERMISSION_ROLES) {
      expect(DEFAULT_ROLE_PERMISSION_MATRIX[role].length).toBeGreaterThan(0);
    }
  });

  test("ADMIN, GERENTE e DIRETOR_TECNICO tem acesso total aos modulos standard", () => {
    const modules = listStandardModules();
    const actions = listStandardActions();

    for (const role of ["ADMIN", "GERENTE", "DIRETOR_TECNICO"] as const) {
      const grants = DEFAULT_ROLE_PERMISSION_MATRIX[role];
      for (const module of modules) {
        const grant = grants.find((entry) => entry.module === module);
        expect(grant).toBeDefined();
        for (const action of actions) {
          expect(grant!.actions).toContain(action);
        }
      }
    }
  });

  test("CAIXA so tem Dashboard Caixa, Terminal e Financeiro", () => {
    const modules = DEFAULT_ROLE_PERMISSION_MATRIX.CAIXA.map((entry) => entry.module);

    expect(modules.sort()).toEqual(
      ["CAIXA", "CLIENTES", "DASHBOARD_CAIXA", "POS", "PROFORMA_INVOICES"].sort(),
    );
    expect(modules).not.toContain("PRODUTOS");
    expect(modules).not.toContain("RELATORIOS");
    expect(modules).not.toContain("COMPRAS");
    expect(modules).not.toContain("DASHBOARD_FARMACIA");
    expect(modules).not.toContain("UTILIZADORES");
    expect(modules).not.toContain("CONFIGURACOES");
  });

  test("FARMACEUTICO so tem Dashboard Farmacia, Terminal e Farmacia", () => {
    const modules = DEFAULT_ROLE_PERMISSION_MATRIX.FARMACEUTICO.map((entry) => entry.module);

    expect(modules.sort()).toEqual(
      [
        "CLIENTES",
        "COMPRAS",
        "DASHBOARD_FARMACIA",
        "FORNECEDORES",
        "INVENTARIO",
        "LOTES",
        "POS",
        "PRODUTOS",
        "PROFORMA_INVOICES",
      ].sort(),
    );
    expect(modules).not.toContain("RELATORIOS");
    expect(modules).not.toContain("UTILIZADORES");
    expect(modules).not.toContain("CONFIGURACOES");
    expect(modules).not.toContain("DASHBOARD_CAIXA");
    expect(modules).not.toContain("CAIXA");
  });

  test("expandRolePermissionMatrix gera linhas unicas role+module+action", () => {
    const rows = expandRolePermissionMatrix();
    const keys = new Set(rows.map((row) => `${row.role}:${row.module}:${row.action}`));

    expect(rows.length).toBe(keys.size);
    expect(rows.length).toBeGreaterThan(150);
  });

  test("acoes criticas estao marcadas", () => {
    expect(isCriticalPermissionAction("APPROVE")).toBe(true);
    expect(isCriticalPermissionAction("VIEW")).toBe(false);
  });
});
