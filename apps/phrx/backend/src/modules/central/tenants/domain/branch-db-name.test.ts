import { describe, expect, test } from "bun:test";
import {
  buildBranchDbName,
  isCanonicalBranchDbName,
  parseCanonicalBranchDbName,
} from "./branch-db-name";

describe("buildBranchDbName", () => {
  test("padrão phrx_tenant_{tenantId}_branch_{branchId}", () => {
    expect(buildBranchDbName(1, 1)).toBe("phrx_tenant_1_branch_1");
    expect(buildBranchDbName("1", "2")).toBe("phrx_tenant_1_branch_2");
    expect(buildBranchDbName(BigInt(9), BigInt(42))).toBe(
      "phrx_tenant_9_branch_42",
    );
  });

  test("rejeita identificadores não numéricos / mutáveis", () => {
    expect(() => buildBranchDbName("momade_vasconcelos", 1)).toThrow();
    expect(() => buildBranchDbName(1, "AA51BE1E")).toThrow();
    expect(() => buildBranchDbName("", "1")).toThrow();
  });
});

describe("isCanonicalBranchDbName / parse", () => {
  test("reconhece o padrão canónico", () => {
    expect(isCanonicalBranchDbName("phrx_tenant_1_branch_1")).toBe(true);
    expect(isCanonicalBranchDbName("tenant_momade_vasconcelos")).toBe(false);
    expect(isCanonicalBranchDbName("tenant_1_branch_67676902934f4f27")).toBe(
      false,
    );
  });

  test("parse extrai ids", () => {
    expect(parseCanonicalBranchDbName("phrx_tenant_1_branch_2")).toEqual({
      tenantId: "1",
      branchId: "2",
    });
    expect(parseCanonicalBranchDbName("tenant_momade_vasconcelos")).toBeNull();
  });
});
