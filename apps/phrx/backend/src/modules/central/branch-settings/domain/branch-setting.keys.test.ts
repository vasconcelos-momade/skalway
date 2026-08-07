import { describe, expect, test } from "bun:test";
import {
  BRANCH_SETTING_KEYS,
  buildDefaultBranchSettings,
} from "./branch-setting.keys";

describe("buildDefaultBranchSettings", () => {
  test("usa nome/código da branch e não inventa contacto/NUIT", () => {
    const items = buildDefaultBranchSettings({
      branchName: "Farmácia Maputo Centro",
      branchCode: "MAP-01",
    });

    const byKey = Object.fromEntries(items.map((i) => [i.key, i.value]));

    expect(byKey[BRANCH_SETTING_KEYS.name]).toBe("Farmácia Maputo Centro");
    expect(byKey[BRANCH_SETTING_KEYS.code]).toBe("MAP-01");
    expect(byKey[BRANCH_SETTING_KEYS.nomeLegal]).toBe("Farmácia Maputo Centro");
    expect(byKey[BRANCH_SETTING_KEYS.email]).toBeNull();
    expect(byKey[BRANCH_SETTING_KEYS.telefone]).toBeNull();
    expect(byKey[BRANCH_SETTING_KEYS.endereco]).toBeNull();
    expect(byKey[BRANCH_SETTING_KEYS.cidade]).toBeNull();
    expect(byKey[BRANCH_SETTING_KEYS.provincia]).toBeNull();
    expect(byKey[BRANCH_SETTING_KEYS.nuit]).toBeNull();
    expect(byKey[BRANCH_SETTING_KEYS.nomeExibido]).toBeNull();
  });

  test("não usa tenantName nem email do dono como fallback implícito", () => {
    const items = buildDefaultBranchSettings({
      branchName: "Filial Beira",
      // Se alguém passar tenantName por engano no nomeLegal, só entra se for explícito.
      nomeLegal: "Filial Beira",
      email: null,
    });
    const byKey = Object.fromEntries(items.map((i) => [i.key, i.value]));
    expect(byKey[BRANCH_SETTING_KEYS.nomeLegal]).toBe("Filial Beira");
    expect(byKey[BRANCH_SETTING_KEYS.email]).toBeNull();
    expect(JSON.stringify(byKey)).not.toContain("Momade");
    expect(JSON.stringify(byKey)).not.toContain("@gmail.com");
  });

  test("respeita valores explícitos de contacto/fiscal", () => {
    const items = buildDefaultBranchSettings({
      branchName: "Filial X",
      email: "filial@farmacia.mz",
      nuit: "123456789",
      cidade: "Maputo",
      provincia: "Maputo",
    });
    const byKey = Object.fromEntries(items.map((i) => [i.key, i.value]));
    expect(byKey[BRANCH_SETTING_KEYS.email]).toBe("filial@farmacia.mz");
    expect(byKey[BRANCH_SETTING_KEYS.nuit]).toBe("123456789");
    expect(byKey[BRANCH_SETTING_KEYS.cidade]).toBe("Maputo");
    expect(byKey[BRANCH_SETTING_KEYS.provincia]).toBe("Maputo");
  });
});

describe("preferência de nome na fatura", () => {
  test("documento.nomeExibido > fiscal.nomeLegal > branch.name", () => {
    const resolve = (
      map: Record<string, unknown>,
      branchName: string | null,
    ) => {
      const asText = (v: unknown) => {
        if (v == null) return null;
        const t = String(v).trim();
        return t.length > 0 ? t : null;
      };
      return (
        asText(map[BRANCH_SETTING_KEYS.nomeExibido]) ??
        asText(map[BRANCH_SETTING_KEYS.nomeLegal]) ??
        asText(map[BRANCH_SETTING_KEYS.name]) ??
        branchName
      );
    };

    expect(
      resolve(
        {
          [BRANCH_SETTING_KEYS.nomeExibido]: "Nome na Fatura",
          [BRANCH_SETTING_KEYS.nomeLegal]: "Nome Legal",
          [BRANCH_SETTING_KEYS.name]: "Branch Name",
        },
        "DB Branch",
      ),
    ).toBe("Nome na Fatura");

    expect(
      resolve(
        {
          [BRANCH_SETTING_KEYS.nomeLegal]: "Nome Legal",
          [BRANCH_SETTING_KEYS.name]: "Branch Name",
        },
        "DB Branch",
      ),
    ).toBe("Nome Legal");

    expect(
      resolve({ [BRANCH_SETTING_KEYS.name]: "Branch Name" }, "DB Branch"),
    ).toBe("Branch Name");

    expect(resolve({}, "DB Branch")).toBe("DB Branch");
    expect(resolve({}, null)).toBeNull();
  });
});
