import { describe, expect, test } from "bun:test";
import {
  assertRecordVisibleToScope,
  isManagementRole,
  isOperationalRole,
  resolveDataScope,
  userScopeWhere,
} from "./data-scope";
import { ForbiddenApiError } from "../../../shared/http/api-error";

describe("data-scope", () => {
  test("CAIXA e FARMACEUTICO sao operacionais", () => {
    expect(isOperationalRole("CAIXA")).toBe(true);
    expect(isOperationalRole("FARMACEUTICO")).toBe(true);
    expect(isManagementRole("ADMIN")).toBe(true);
    expect(isManagementRole("GERENTE")).toBe(true);
    expect(isManagementRole("DIRETOR_TECNICO")).toBe(true);
  });

  test("operacional forca filterUserId do actor e ignora requestedUserId", () => {
    const scope = resolveDataScope({
      actorUserId: "10",
      role: "CAIXA",
      requestedUserId: "99",
    });

    expect(scope.mode).toBe("OWN");
    expect(scope.filterUserId).toBe("10");
    expect(userScopeWhere(scope)).toEqual({ userId: 10n });
  });

  test("gestao ve tudo e aceita filtro opcional", () => {
    const all = resolveDataScope({
      actorUserId: "1",
      role: "ADMIN",
    });
    expect(all.mode).toBe("ALL");
    expect(all.filterUserId).toBeNull();
    expect(userScopeWhere(all)).toEqual({});

    const filtered = resolveDataScope({
      actorUserId: "1",
      role: "GERENTE",
      requestedUserId: "42",
    });
    expect(filtered.mode).toBe("ALL");
    expect(filtered.filterUserId).toBe("42");
  });

  test("assertRecordVisibleToScope bloqueia registos alheios para operacional", () => {
    const scope = resolveDataScope({ actorUserId: "5", role: "FARMACEUTICO" });
    expect(() => assertRecordVisibleToScope(scope, "5")).not.toThrow();
    expect(() => assertRecordVisibleToScope(scope, "9")).toThrow(ForbiddenApiError);
  });
});
