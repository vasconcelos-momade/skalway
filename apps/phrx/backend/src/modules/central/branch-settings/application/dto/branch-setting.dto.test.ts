import { describe, expect, test } from "bun:test";
import {
  branchIdParamSchema,
  updateBranchSettingsSchema,
} from "./branch-setting.dto";

describe("branchIdParamSchema", () => {
  test("aceita branchId numérico", () => {
    expect(branchIdParamSchema.parse({ branchId: "42" }).branchId).toBe("42");
  });

  test("rejeita branchId inválido", () => {
    expect(() => branchIdParamSchema.parse({ branchId: "abc" })).toThrow();
  });
});

describe("updateBranchSettingsSchema", () => {
  test("exige pelo menos uma chave", () => {
    expect(() => updateBranchSettingsSchema.parse({ settings: {} })).toThrow();
  });

  test("aceita mapa de settings", () => {
    const result = updateBranchSettingsSchema.parse({
      settings: {
        "branch.name": "Farmácia Centro",
        "fiscal.nuit": "123456789",
        "fiscal.iva": true,
      },
    });
    expect(result.settings["branch.name"]).toBe("Farmácia Centro");
    expect(result.settings["fiscal.iva"]).toBe(true);
  });
});
